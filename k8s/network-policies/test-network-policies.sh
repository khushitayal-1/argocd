#!/bin/bash

# Network Policy Testing Script
# This script tests the network policy scenarios:
# Scenario 1: Pod A (namespace-a) can communicate with Pod B (namespace-b)
# Scenario 2: Pod A (namespace-a) cannot communicate with Pod C (namespace-c)

set -e

echo "============================================"
echo "Network Policy Testing Script"
echo "============================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to test communication
test_communication() {
    local source_pod=$1
    local source_ns=$2
    local target_service=$3
    local target_ns=$4
    local port=$5
    local should_succeed=$6
    
    echo -e "${YELLOW}Testing: $source_pod ($source_ns) -> $target_service ($target_ns):$port${NC}"
    
    # Wait for pod to be ready
    echo "  Waiting for pod to be ready..."
    kubectl wait --for=condition=Ready pod/$source_pod -n $source_ns --timeout=60s 2>/dev/null || echo "  Warning: Pod not ready"
    
    # Test connectivity
    if kubectl exec -it $source_pod -n $source_ns -- curl -v http://$target_service.$target_ns.svc.cluster.local:$port/ --max-time 5 &>/dev/null; then
        if [ "$should_succeed" = "true" ]; then
            echo -e "  ${GREEN}✓ SUCCESS: Communication allowed (as expected)${NC}"
            return 0
        else
            echo -e "  ${RED}✗ FAILED: Communication allowed (should be blocked)${NC}"
            return 1
        fi
    else
        if [ "$should_succeed" = "false" ]; then
            echo -e "  ${GREEN}✓ SUCCESS: Communication blocked (as expected)${NC}"
            return 0
        else
            echo -e "  ${RED}✗ FAILED: Communication blocked (should be allowed)${NC}"
            return 1
        fi
    fi
}

# Main test sequence
echo "Step 1: Creating namespaces and network policies..."
kubectl apply -f k8s/network-policies/01-namespaces.yaml
kubectl apply -f k8s/network-policies/02-network-policies.yaml

echo ""
echo "Step 2: Creating test pods..."
kubectl apply -f k8s/network-policies/03-test-pods.yaml

echo ""
echo "Step 3: Waiting for all pods to be ready..."
kubectl wait --for=condition=Ready pod/pod-a -n namespace-a --timeout=120s
kubectl wait --for=condition=Ready pod/pod-b -n namespace-b --timeout=120s
kubectl wait --for=condition=Ready pod/pod-c -n namespace-c --timeout=120s

echo ""
echo "============================================"
echo "Test Execution"
echo "============================================"
echo ""

PASS=0
FAIL=0

# Test 1: Pod A -> Pod B (should succeed)
if test_communication "pod-a" "namespace-a" "pod-b-svc" "namespace-b" "8080" "true"; then
    PASS=$((PASS+1))
else
    FAIL=$((FAIL+1))
fi

echo ""

# Test 2: Pod A -> Pod C (should fail)
if test_communication "pod-a" "namespace-a" "pod-c-svc" "namespace-c" "8080" "false"; then
    PASS=$((PASS+1))
else
    FAIL=$((FAIL+1))
fi

echo ""

# Test 3: Check network policies
echo -e "${YELLOW}Checking applied network policies...${NC}"
echo "  Namespace A policies:"
kubectl get networkpolicies -n namespace-a

echo ""
echo "  Namespace B policies:"
kubectl get networkpolicies -n namespace-b

echo ""
echo "  Namespace C policies:"
kubectl get networkpolicies -n namespace-c

echo ""
echo "============================================"
echo "Test Summary"
echo "============================================"
echo -e "Passed: ${GREEN}$PASS${NC}"
echo -e "Failed: ${RED}$FAIL${NC}"
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed!${NC}"
    exit 1
fi
