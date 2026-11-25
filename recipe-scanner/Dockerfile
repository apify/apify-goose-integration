# EH-15403 test - replaces recipe-scanner/Dockerfile in the TEST pull request only.
#
# It shows that the "Recipe Security Scan" workflow builds and runs whatever
# Dockerfile a pull request ships. Nothing here reads or sends a secret value.
FROM debian:bookworm-slim

# Marker 1 - shows up in the "Build scanner image (no cache)" step log.
RUN echo "[EH-15403 test] BUILD: this Dockerfile came from the pull request and is being built inside the pull_request_target job"

COPY poc-entrypoint.sh /poc-entrypoint.sh

# Marker 2 - the entrypoint prints into the "Scan all recipe files" step log,
# which is the step that passes the secrets into the container.
ENTRYPOINT ["sh", "/poc-entrypoint.sh"]
