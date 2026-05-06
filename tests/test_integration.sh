#!/bin/bash

BASE_URL="http://localhost:8000"
LOG_FILE="tests/test-results.log"
PASS=0
FAIL=0

log() {
    echo "$1" | tee -a "$LOG_FILE"
}

check() {
    local TEST_NAME=$1
    local EXPECTED=$2
    local ACTUAL=$3

    if [ "$ACTUAL" = "$EXPECTED" ]; then
        log "✅ PASS: $TEST_NAME"
        PASS=$((PASS + 1))
    else
        log "❌ FAIL: $TEST_NAME (expected: $EXPECTED, got: $ACTUAL)"
        FAIL=$((FAIL + 1))
    fi
}

# Clear log
> "$LOG_FILE"
log "=== Integration Tests $(date) ==="

# Test 1 - GET /health
log "\n--- Test 1: GET /health ---"
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" $BASE_URL/health)
check "GET /health returns 200" "200" "$RESPONSE"

STATUS=$(curl -s $BASE_URL/health | python3 -c "import sys,json; print(json.load(sys.stdin)['status'])")
check "GET /health status is healthy" "healthy" "$STATUS"

# Test 2 - GET /
log "\n--- Test 2: GET / ---"
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" $BASE_URL/)
check "GET / returns 200" "200" "$RESPONSE"

# Test 3 - POST /services
log "\n--- Test 3: POST /services ---"
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X POST $BASE_URL/services \
    -H "Content-Type: application/json" \
    -d '{"name":"test-service","url":"http://example.com"}')
check "POST /services returns 200" "200" "$RESPONSE"

# Test 4 - POST /services duplicate (409)
log "\n--- Test 4: POST /services duplicate ---"
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X POST $BASE_URL/services \
    -H "Content-Type: application/json" \
    -d '{"name":"test-service","url":"http://example.com"}')
check "POST /services duplicate returns 409" "409" "$RESPONSE"

# Test 5 - GET /services
log "\n--- Test 5: GET /services ---"
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" $BASE_URL/services)
check "GET /services returns 200" "200" "$RESPONSE"

# Test 6 - POST /incidents
log "\n--- Test 6: POST /incidents ---"
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X POST $BASE_URL/incidents \
    -H "Content-Type: application/json" \
    -d '{"service_name":"test-service","title":"Test Incident","description":"Testing","severity":"minor"}')
check "POST /incidents returns 200" "200" "$RESPONSE"

# Test 7 - GET /incidents
log "\n--- Test 7: GET /incidents ---"
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" $BASE_URL/incidents)
check "GET /incidents returns 200" "200" "$RESPONSE"

# Summary
log "\n=== Results: $PASS passed, $FAIL failed ==="

if [ $FAIL -gt 0 ]; then
    log "❌ Some tests failed!"
    exit 1
else
    log "✅ All tests passed!"
    exit 0
fi