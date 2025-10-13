#!/bin/bash
################################################################################
# JWT Test Token Generator
#
# Generates a valid JWT token for testing the backend API
#
# Usage:
#   ./generate_jwt_token.sh [email]
#
# Example:
#   ./generate_jwt_token.sh castlekong1019@gmail.com
#
# The token is valid for 24 hours and uses the HS512 algorithm
################################################################################

# Secret key from application.yml
SECRET_KEY="mySecretKeyForJWTTokenGenerationWhichShouldBeVeryLongAndSecureInProduction"
EMAIL="${1:-castlekong1019@gmail.com}"

# Calculate timestamps
NOW=$(date +%s)
EXP=$((NOW + 86400))  # 24 hours

# Create header (base64url encoded)
HEADER='{"alg":"HS512","typ":"JWT"}'
HEADER_B64=$(echo -n "$HEADER" | base64 | tr -d '=' | tr '/+' '_-' | tr -d '\n')

# Create payload (base64url encoded)
PAYLOAD="{\"sub\":\"$EMAIL\",\"auth\":\"ROLE_USER\",\"iat\":$NOW,\"exp\":$EXP}"
PAYLOAD_B64=$(echo -n "$PAYLOAD" | base64 | tr -d '=' | tr '/+' '_-' | tr -d '\n')

# Create signature (HMAC SHA-512)
SIGNATURE=$(echo -n "${HEADER_B64}.${PAYLOAD_B64}" | openssl dgst -sha512 -hmac "$SECRET_KEY" -binary | base64 | tr -d '=' | tr '/+' '_-' | tr -d '\n')

# Combine into JWT
TOKEN="${HEADER_B64}.${PAYLOAD_B64}.${SIGNATURE}"

# Output
echo "================================================================================"
echo "JWT Test Token Generated"
echo "================================================================================"
echo "Email: $EMAIL"
echo "Expiration: 24 hours"
echo ""
echo "Token:"
echo "$TOKEN"
echo ""
echo "Usage Example:"
echo "curl -H \"Authorization: Bearer $TOKEN\" http://localhost:8080/api/places/1/reservations?startDate=2025-01-01\\&endDate=2025-01-31"
echo ""
echo "Export as variable:"
echo "export TOKEN=\"$TOKEN\""
echo "curl -H \"Authorization: Bearer \\\$TOKEN\" http://localhost:8080/api/places"
echo "================================================================================"
