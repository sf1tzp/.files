start_ollama:
    nerdctl compose -f ~/.files/homelab/services/ollama.yaml up -d

stop_ollama:
    nerdctl compose -f ~/.files/homelab/services/ollama.yaml down
