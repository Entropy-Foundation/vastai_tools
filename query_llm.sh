#!/bin/bash

curl http://43.100.46.13:8080/v1/chat/completions \
-H "Content-Type: application/json" \
-d '{
    "messages": [
        {"role": "user", "content": "What is the capital of Qatar?"}
    ]
}'