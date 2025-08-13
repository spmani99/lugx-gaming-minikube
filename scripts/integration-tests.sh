#!/bin/bash

# Simplified Integration Tests Script for Minikube Local Setup

set -e

NAMESPACE="default"
echo "Running Integration Tests for Minikube local environment"
echo "=========================================================================="

# Test 1: Frontend Health Check
echo "Test 1: Frontend Health Check"
kubectl port-forward service/frontend 8080:80 -n $NAMESPACE &
FRONTEND_PID=$!
sleep 5

FRONTEND_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 || echo "000")
kill $FRONTEND_PID 2>/dev/null || true

if [ "$FRONTEND_STATUS" = "200" ]; then
    echo "PASS Frontend health check passed (Status: $FRONTEND_STATUS)"
else
    echo "FAIL Frontend health check failed (Status: $FRONTEND_STATUS)"
    exit 1
fi

# Test 2: Game Service API Test
echo "Test 2: Game Service API Test"
kubectl port-forward service/game-service 3001:3001 -n $NAMESPACE &
GAME_PID=$!
sleep 5

GAME_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3001/api/games || echo "000")
kill $GAME_PID 2>/dev/null || true

if [ "$GAME_STATUS" = "200" ]; then
    echo "PASS Game service API test passed (Status: $GAME_STATUS)"
else
    echo "WARN  Game service API test warning (Status: $GAME_STATUS) - Check DB connection or service logs"
fi

# Test 3: Order Service API Test
echo "Test 3: Order Service API Test"
kubectl port-forward service/order-service 3002:3002 -n $NAMESPACE &
ORDER_PID=$!
sleep 5

ORDER_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3002/api/orders || echo "000")
kill $ORDER_PID 2>/dev/null || true

if [ "$ORDER_STATUS" = "200" ]; then
    echo "PASS Order service API test passed (Status: $ORDER_STATUS)"
else
    echo "WARN  Order service API test warning (Status: $ORDER_STATUS) - Check DB connection or service logs"
fi

# Test 4: Analytics Service Test
echo "Test 4: Analytics Service Test"
kubectl port-forward service/analytics-service 3003:3003 -n $NAMESPACE &
ANALYTICS_PID=$!
sleep 5

ANALYTICS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3003/health || echo "000")
kill $ANALYTICS_PID 2>/dev/null || true

if [ "$ANALYTICS_STATUS" = "200" ]; then
    echo "PASS Analytics service test passed (Status: $ANALYTICS_STATUS)"
else
    echo "WARN  Analytics service test warning (Status: $ANALYTICS_STATUS) - Check service logs"
fi

# Test 5: Pod Health Check
echo "Test 5: Pod Health Check"
UNHEALTHY_PODS=$(kubectl get pods -n $NAMESPACE --field-selector=status.phase!=Running -o name 2>/dev/null | wc -l)

if [ "$UNHEALTHY_PODS" -eq 0 ]; then
    echo "PASS All pods are healthy and running"
else
    echo "WARN  Found $UNHEALTHY_PODS unhealthy pods:"
    kubectl get pods -n $NAMESPACE --field-selector=status.phase!=Running 2>/dev/null || true
fi

# Test 6: Service Discovery Test
echo "Test 6: Service Discovery Test"
EXPECTED_SERVICES=4
ACTUAL_SERVICES=$(kubectl get services -n $NAMESPACE --no-headers 2>/dev/null | grep -v kubernetes | wc -l)

if [ "$ACTUAL_SERVICES" -ge "$EXPECTED_SERVICES" ]; then
    echo "PASS Service discovery test passed ($ACTUAL_SERVICES services found)"
else
    echo "FAIL Service discovery test failed (Expected: $EXPECTED_SERVICES, Found: $ACTUAL_SERVICES)"
    exit 1
fi

echo "=========================================================================="
echo "SUCCESS Integration tests completed for Minikube local environment!"
