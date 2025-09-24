#!/bin/bash

curl http://localhost:8080/v1/chat/completions \
-H "Content-Type: application/json" \
-d '{
    "messages": [
        {"role": "user", "content": "What is the capital of Qatar?"}
    ]
}'