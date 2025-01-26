# Helm Image Puller 🚀

Bash script to extract and pull Docker images from a Helm chart for air-gapped environments.

## 📌 Features

- 🏗 **Extracts images** from a given Helm chart.
- 📦 **Pulls and saves** Docker images as `.tar` files.
- 🔄 **Supports offline environments** where pulling images is restricted.
- 📊 **Generates a report** with image statuses and sizes.

## 🔧 Installation

Ensure you have `helm` and `docker` installed:

```bash
helm version
docker version
```

## 🚀 Usage

Run the script with:

```bash
./pull_helm_images.sh -p -s my-helm-chart
```

Replace `my-helm-chart` with your Helm chart name or path.

## 📂 Example Output

```
==> Fetching images for Helm chart: my-helm-chart
✅ Successfully pulled image: nginx:latest
✅ Image saved to: docker_images/nginx_latest.tar
```

## 🛠 Requirements

- Bash (`>=4.0`)
- Helm (`>=3.0`)
- Docker (`>=20.0`)

## ⚖️ License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
