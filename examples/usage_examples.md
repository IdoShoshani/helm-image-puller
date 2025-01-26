# Helm Image Puller - Usage Examples

## 🔹 Example 1: Extract and Pull Images from a Public Helm Chart

```bash
./pull_helm_images.sh -p -s prometheus-community/kube-prometheus-stack
```

**Expected Output:**

```
==> Fetching images for Helm chart: prometheus-community/kube-prometheus-stack
✅ Successfully pulled image: quay.io/prometheus/prometheus:v2.37.0
✅ Image saved to: docker_images/quay.io_prometheus_prometheus_v2.37.0.tar
...
```

## 🔹 Example 2: Extract Images Only (Without Pulling)

```bash
./pull_helm_images.sh -s my-private-chart > image_list.txt
```

This will save a list of images in `image_list.txt` without pulling them.

## 🔹 Example 3: Pull and Save Images in a Custom Directory

```bash
OUTPUT_DIR=/mnt/offline_images ./pull_helm_images.sh -p -s my-private-chart
```

This will save images in `/mnt/offline_images` instead of the default folder.
