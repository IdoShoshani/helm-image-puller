# Helm Image Puller 🚀

A simple bash script for extracting and pulling Docker images from Helm charts, designed for use in air-gapped environments.

## 📌 Key Features

- 🏗 Extracts container images from a Helm chart.
- 📦 Saves pulled images as `.tar` archives.
- 🔄 Enables usage in offline or restricted networks.
- 📊 Generates a summary report with image details.

## 🔧 Installation

Make sure `helm` and `docker` are installed:

```bash
helm version
docker version
```

## 🚀 How to Use

Run the script with:

```bash
./pull_helm_images.sh -p -s my-helm-chart
```

Replace `my-helm-chart` with the appropriate Helm chart name or path.

## 📂 Example Output

```
==> Fetching images for Helm chart: my-helm-chart
✅ Successfully pulled image: nginx:latest
✅ Image saved to: docker_images/nginx_latest.tar
```

## 📦 Uploading Images to a Private Registry

Once the images have been saved, they can be loaded and pushed to a private registry.

### **1️⃣ Load the saved image**

```bash
docker load -i docker_images/nginx_latest.tar
```

### **2️⃣ Tag the image for the registry**

```bash
docker tag nginx:latest my-registry.com/my-namespace/nginx:latest
```

### **3️⃣ Push the image**

```bash
docker push my-registry.com/my-namespace/nginx:latest
```

### 🔐 Authentication (if required)

If your registry requires authentication, log in first:

```bash
docker login my-registry.com
```

Then push the image as usual.

### 💡 Automating Multiple Images

For handling multiple images, use this script:

```bash
for image in docker_images/*.tar; do
    docker load -i "$image"
    image_name=$(basename "$image" .tar | sed 's/_/:/g')
    docker tag "$image_name" my-registry.com/my-namespace/"$image_name"
    docker push my-registry.com/my-namespace/"$image_name"
done
```

## 🛠 System Requirements

- Bash (`>=4.0`)
- Helm (`>=3.0`)
- Docker (`>=20.0`)

## ⚖️ License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
