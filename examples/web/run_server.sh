odin build . -out:main -target:js_wasm32
python3 -m http.server 8001
