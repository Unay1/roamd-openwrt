#!/bin/sh
set -eu

command -v openssl >/dev/null 2>&1 || {
    echo "openssl не найден. Установите пакет openssl." >&2
    exit 1
}

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
KEY_DIR="$ROOT/keys"
PRIVATE_KEY="${TMPDIR:-/tmp}/roamd-apk-signing-$$.pem"

mkdir -p "$KEY_DIR"
umask 077

if [ -e "$KEY_DIR/roamd-apk.rsa.pub" ]; then
    echo "Публичный ключ уже существует: $KEY_DIR/roamd-apk.rsa.pub" >&2
    echo "Не перезаписываю существующую пару ключей." >&2
    exit 1
fi

openssl genrsa -out "$PRIVATE_KEY" 2048
openssl rsa -in "$PRIVATE_KEY" -pubout -out "$KEY_DIR/roamd-apk.rsa.pub"

echo
echo "Пара ключей создана."
echo "Публичный ключ: $KEY_DIR/roamd-apk.rsa.pub"
echo "Приватный ключ: $PRIVATE_KEY"
echo
echo "Добавьте содержимое приватного ключа в GitHub Actions Secret APK_SIGN_KEY."
echo "Приватный ключ нельзя добавлять в Git или отправлять в публичные сообщения."
