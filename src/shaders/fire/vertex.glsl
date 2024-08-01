out vec3 vPosition;
out vec3 vOrigin;
out vec3 vDirection;

void main() {
  vPosition = position;
  vOrigin = vec3(inverse(modelMatrix) * vec4(cameraPosition, 1.)).xyz;
  vDirection = position - vOrigin;

  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.);
}
