# Secure Wolfi Container Images & CI/CD Pipelines

This repository contains configurations and **CI/CD** automation using **GitHub Actions** to build, scan, and publish minimal, secure, and **Zero-CVE** oriented container images using **Chainguard Wolfi** as the base image.

This project demonstrates two primary approaches in modern container engineering:
1. **APKO-based Distroless Image** (e.g., Java 25 Distroless supporting multi-architecture AMD64 & ARM64).
2. **Dockerfile-based Custom Runtime** (e.g., Quarkus runtime with integrated Headless LibreOffice).

---

## Security Features & Supply Chain Best Practices

Every image built is maintained under software supply chain security standards:

* **Zero-CVE Baseline:** Uses minimal `wolfi-base` packages to reduce the attack surface.
* **Multi-Architecture Support:** Automatically builds and validates images for both `linux/amd64` and `linux/arm64` architectures.
* **Automated Vulnerability Scanning:** Utilizes **Aqua Security Trivy** to detect OS and library vulnerabilities.
* **SBOM Generation & Comparison:** Generates Software Bill of Materials (SBOM) using **Syft** and tracks package version changes across builds.
* **Cryptographic Signing & Attestation:** Signs images and SBOMs using **Sigstore Cosign** via GitHub OIDC.
* **Immutable Artifacts:** Prevents unauthorized overriding of manual release tags.

---

## Repository Structure

```text
├── .github/
│   └── workflows/
│       ├── java25-distroless.yml  # APKO pipeline for Java 25 Distroless
│       └── main.yml               # Dockerfile pipeline for Quarkus + LibreOffice
├── apko.yaml                      # Declarative APKO configuration for Wolfi Java
├── Dockerfile                     # Custom image configuration (Java + LibreOffice)
├── headless.sh                    # Headless LibreOffice wrapper script
└── compare_sbom.py                # Python script for comparing SBOM package versions
```
---

## Workflow Details

### 1. Wolfi Java 25 Distroless (`java25-distroless.yml`)

* **Tools:** `apko`, `crane`, `syft`, `cosign`, `trivy`.
* **Triggers:** Push to `main`, daily cron schedule (at 02:23 UTC), or manual `workflow_dispatch` with an optional `release_tag`.
* **Pipeline Steps:**
1. Build multi-architecture tarballs using `apko` (`amd64` & `arm64`).
2. Perform smoke tests and non-root user validation (`UID 65532` / `nonroot`).
3. Scan for vulnerabilities using Trivy (`exit-code: 1` on detection).
4. Generate SPDX SBOMs via Syft.
5. Compare package versions against the existing registry image (`ghcr.io`).
6. Push, sign, and attest the SBOMs using Cosign.



### 2. Quarkus & LibreOffice Runtime (`main.yml`)

* **Tools:** `docker`, `trivy`, `docker/build-push-action`.
* **Triggers:** Push to `main` or Pull Requests.
* **Pipeline Steps:**
1. Build the image locally from the `Dockerfile`.
2. Run Trivy vulnerability scanning targeting `CRITICAL` and `HIGH` severity levels.
3. On successful push to `main`, generate automatic tags (including `latest` and `v<run_number>`) and publish to the **GitHub Container Registry (GHCR)**.



---

## How to Pull Images

The published images can be pulled directly from your GitHub Container Registry:

```bash
# Pull Java 25 Distroless Image
docker pull ghcr.io/<github-username>/wolfi-jdk-distroless:latest

# Pull Quarkus LibreOffice Image
docker pull ghcr.io/<github-username>/quarkus-libre:latest
```

---

## Image Security Verification (Cosign)

You can verify the digital signature and SBOM attestations of the published images using Cosign:

```bash
# Verify OCI Index Signature
cosign verify ghcr.io/jocerdikiawann/wolfi-jdk-distroless@<digest> \
  --certificate-identity "https://github.com/Jocerdikiawann/wolfi-images/.github/workflows/java25-distroless.yml@refs/heads/main" \
  --certificate-oidc-issuer "https://token.actions.githubusercontent.com"
```

---
