POST http://localhost:8001/api/v1/namespaces/default/services/ollama-service:80/proxy/api/generate
{
  "model": "llama3",
  "prompt": "why is the sky blue?"
}
