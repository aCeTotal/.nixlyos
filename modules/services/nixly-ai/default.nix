{ config, pkgs, lib, ... }:

# Local Ollama + `ai` / `nixly-ai` chat TUI. Retrieval calls go to the
# RAG server at https://ai.aceclan.no.
#
# Token (must match the server's /etc/nixly-rag/token):
#   sudo install -d -m 0755 /etc/nixly-ai
#   sudo install -m 0644 -o root -g root <(echo TOKEN) /etc/nixly-ai/token
#
# Override the model with NIXLY_AI_MODEL or the rag URL with NIXLY_RAG_URL
# in the user's environment.

let
  ragUrl = "https://ai.aceclan.no";
  model = "qwen2.5-coder:7b-instruct";
  ollamaPort = 11434;

  cliPython = pkgs.python312.withPackages (ps: with ps; [
    httpx
    rich
    prompt-toolkit
  ]);

  # Bundle the python entrypoint as a versioned store path so the wrapper
  # below is just a thin env-bootstrap.
  cliScript = pkgs.runCommand "nixly-ai-cli" { } ''
    install -Dm0644 ${./cli.py} $out/share/nixly-ai/cli.py
  '';

  mkBin = name: pkgs.writeShellScriptBin name ''
    export NIXLY_RAG_URL="''${NIXLY_RAG_URL:-${ragUrl}}"
    export NIXLY_OLLAMA_URL="''${NIXLY_OLLAMA_URL:-http://127.0.0.1:${toString ollamaPort}}"
    export NIXLY_AI_MODEL="''${NIXLY_AI_MODEL:-${model}}"
    # Force UTF-8 so the rounded box-drawing glyphs render under any locale.
    export PYTHONIOENCODING="''${PYTHONIOENCODING:-utf-8}"
    exec ${cliPython}/bin/python ${cliScript}/share/nixly-ai/cli.py "$@"
  '';
in
{
  # Local Ollama. CUDA primary, CPU offload for layers that don't fit.
  services.ollama = {
    enable = true;
    host = "127.0.0.1";
    port = ollamaPort;
    package = pkgs.ollama-cuda;
    loadModels = [ model ];
  };

  # Keep the model warm; single-stream throughput.
  systemd.services.ollama.environment = {
    OLLAMA_NUM_PARALLEL = "1";
    OLLAMA_MAX_LOADED_MODELS = "1";
    OLLAMA_KEEP_ALIVE = "24h";
    OLLAMA_FLASH_ATTENTION = "1";
    OLLAMA_KV_CACHE_TYPE = "q8_0";
  };

  systemd.services.ollama.serviceConfig = {
    CPUWeight = 200;
    Nice = -5;
  };

  # Token directory; the file itself is dropped in by the operator
  # (see comment block above) so we don't keep secrets in the Nix store.
  systemd.tmpfiles.rules = [
    "d /etc/nixly-ai 0755 root root -"
  ];

  environment.systemPackages = [
    (mkBin "ai")
    (mkBin "nixly-ai")
  ];
}
