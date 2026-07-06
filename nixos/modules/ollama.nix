# Ollama LLM server with ROCm acceleration for AMD Radeon 680M (gfx1035)
{ config, pkgs, ... }:

{
  services.ollama = {
    enable = false;
    package = pkgs.ollama-rocm;
    # Radeon 680M is gfx1035 (RDNA2). ROCm doesn't officially target it,
    # but treating it as gfx1030 via HSA_OVERRIDE_GFX_VERSION works in practice.
    rocmOverrideGfx = "10.3.0";
    host = "0.0.0.0";
    port = 11434;
    openFirewall = true;
    loadModels = [ "qwen3:1.7b" ];
  };
}
