#!/usr/bin/env bash

###############################################################################
# Bash script to pull & save Docker images derived from a Helm chart.
# Dynamically extracts images from the specified Helm chart.
###############################################################################

# Halt on errors and ensure failures in pipes cause the script to fail
set -e
set -o pipefail

# --- Default Configurable Variables ---
HELM_CHART=""                                    # Helm chart to process
OUTPUT_DIR="${OUTPUT_DIR:-$(pwd)/docker_images}" # Directory where images will be saved

# --- Parse CLI Arguments ---
PULL_IMAGES=false
LIST_ONLY=false

# --- Colors for Terminal Output ---
GREEN=$(tput setaf 2)
RED=$(tput setaf 1)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
CYAN=$(tput setaf 6)
RESET=$(tput sgr0)

# --- Logging & Output Helpers ---
log_info() { echo "${GREEN}[INFO]${RESET} $*"; }
log_error() { echo "${RED}[ERROR]${RESET} $*" >&2; }
log_step() { echo "${BLUE}==>${RESET} $*"; }
log_stat() { echo "${CYAN}[STATS]${RESET} $*"; }

# --- Usage (Help) Function ---
usage() {
    cat <<EOF
Usage: $0 [options]

Options:
  -p             Pull & save images (requires -s with a valid Helm chart).
  -s <chart>     Specify Helm chart name or path to extract images from.
  -h             Display this help message.

Example:
  $0 -p -s prometheus-community/kube-prometheus-stack

Environment Variables:
  OUTPUT_DIR  (default: current_dir/docker_images)

Description:
  This script pulls and saves Docker images referenced by a specified Helm chart.
  Images are stored as .tar files in the OUTPUT_DIR directory.

EOF
    exit 1
}

# --- Validate Output Directory ---
validate_output_dir() {
    mkdir -p "$OUTPUT_DIR"
    if [ ! -w "$OUTPUT_DIR" ]; then
        log_error "Output directory is not writable: $OUTPUT_DIR"
        exit 1
    fi
}

# --- Validate Helm Chart Existence ---
validate_helm_chart() {
    log_step "Validating Helm chart: $HELM_CHART"
    if ! helm show chart "$HELM_CHART" &>/dev/null; then
        log_error "Helm chart '$HELM_CHART' not found or inaccessible."
        exit 1
    fi
    log_info "Helm chart validated successfully."
}

# --- Extract Images from Helm Chart ---
extract_helm_images() {
    # Use helm template to render the chart and grep for image references
    # This approach captures images across different Kubernetes resource types
    local chart_images
    chart_images=$(helm template "$HELM_CHART" | grep -E 'image: *"?[^"]*"?' | sed -E 's/.*image: *"?([^"]*)"?/\1/' | sort -u)

    if [ -z "$chart_images" ]; then
        log_error "No images found in the Helm chart."
        exit 1
    fi

    echo "$chart_images"
}

# --- Check if Docker Daemon is Running ---
check_docker_daemon() {
    if ! docker info &>/dev/null; then
        log_error "Docker daemon is not running or not accessible."
        log_error "Make sure Docker is installed and running."
        log_error "Try running: ${YELLOW}open -a Docker${RESET} (macOS) or restarting the service (Linux)."
        exit 1
    fi
}

# --- Check if required tools are installed ---
check_required_tools() {
    local required_tools=("docker" "helm")
    local missing_tools=()

    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            missing_tools+=("$tool")
        fi
    done

    if [ "${#missing_tools[@]}" -gt 0 ]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        log_error "Please install the missing tools and try again."
        exit 1
    fi
}

# --- Global Counters & Report Array ---
TOTAL_IMAGES=0
SUCCESSFUL_PULLS=0
FAILED_PULLS=0
SUCCESSFUL_SAVES=0
FAILED_SAVES=0
IMAGE_REPORT=()

# --- Pull and Save an Image ---
pull_and_save_image() {
    local image="$1"
    local image_name="${image//\//_}" # replace '/' with '_'
    image_name="${image_name//:/_}"   # replace ':' with '_'
    local image_path="$OUTPUT_DIR/$image_name.tar"
    local retries=3
    local attempt=0

    TOTAL_IMAGES=$((TOTAL_IMAGES + 1))
    local start_time
    start_time=$(date +%s)

    log_step "Processing image: $image"
    log_info "Pulling $image..."

    while [ $attempt -lt $retries ]; do
        if docker pull "$image"; then
            log_info "Successfully pulled $image"
            SUCCESSFUL_PULLS=$((SUCCESSFUL_PULLS + 1))
            local pull_time=$(($(date +%s) - start_time))
            log_stat "Time taken to pull: ${pull_time}s"

            log_info "Saving image to: $image_path"
            if docker save "$image" -o "$image_path"; then
                SUCCESSFUL_SAVES=$((SUCCESSFUL_SAVES + 1))
                local image_size
                image_size=$(du -h "$image_path" | awk '{print $1}')
                log_info "✅ Image saved successfully: $image_path"
                IMAGE_REPORT+=("$image|Pulled|Saved|$image_size")
                return
            else
                log_error "❌ Failed to save image: $image"
                FAILED_SAVES=$((FAILED_SAVES + 1))
                IMAGE_REPORT+=("$image|Pulled|Failed to save|-")
                return
            fi
        else
            attempt=$((attempt + 1))
            log_error "⚠️  Failed to pull image: $image (attempt $attempt/$retries). Retrying..."
            sleep 5
        fi
    done

    log_error "❌ Failed to pull image: $image after $retries attempts. Exiting."
    FAILED_PULLS=$((FAILED_PULLS + 1))
    IMAGE_REPORT+=("$image|Failed to pull|-|-")
    exit 1 # Exit if all attempts failed
}

# --- Print Final Report ---
print_report() {
    log_step "Summary of processed images:"
    log_stat "Total images attempted: $TOTAL_IMAGES"
    log_stat "Successfully pulled:     $SUCCESSFUL_PULLS"
    log_stat "Failed pulls:            $FAILED_PULLS"
    log_stat "Successfully saved:      $SUCCESSFUL_SAVES"
    log_stat "Failed saves:            $FAILED_SAVES"

    printf "\n${CYAN}%-60s %-15s %-15s %-10s${RESET}\n" "Image" "Pull Status" "Save Status" "Size"
    printf "%-60s %-15s %-15s %-10s\n" "----------------------------------------------------------------------" "---------------" "---------------" "----------"
    for entry in "${IMAGE_REPORT[@]}"; do
        IFS='|' read -r img pull_status save_status size <<<"$entry"
        printf "%-60.60s %-15s %-15s %-10s\n" "$img" "$pull_status" "$save_status" "$size"
    done
    printf "%-60s %-15s %-15s %-10s\n" "----------------------------------------------------------------------" "---------------" "---------------" "----------"

    log_info "To load saved images, use: docker load -i <image.tar>"
}

# --- Main Function ---
main() {
    # Validate we have a Helm chart
    if [ -z "$HELM_CHART" ]; then
        log_error "No Helm chart specified. Use -s to specify a chart."
        usage
    fi

    check_required_tools
    validate_output_dir
    check_docker_daemon
    validate_helm_chart

    log_step "Fetching images for Helm chart: $HELM_CHART"
    IMAGES=()
    while IFS= read -r line; do
        IMAGES+=("$line")
    done < <(extract_helm_images)

    if [ "$LIST_ONLY" = true ]; then
        printf "%s\n" "${IMAGES[@]}"
        exit 0
    fi

    if [ "$PULL_IMAGES" = true ]; then
        for image in "${IMAGES[@]}"; do
            pull_and_save_image "$image"
        done
        print_report
    else
        log_info "No pull operation requested. Use -p to pull images."
    fi
}

# --- Parse CLI Arguments ---
while getopts ":ps:o:lh" opt; do
    case "${opt}" in
    p) PULL_IMAGES=true ;;
    s) HELM_CHART="${OPTARG}" ;;
    l) LIST_ONLY=true ;;
    o) OUTPUT_DIR="${OPTARG}" ;;
    h) usage ;;
    *) usage ;;
    esac
done

# --- Invoke Main Function ---
main "$@"
