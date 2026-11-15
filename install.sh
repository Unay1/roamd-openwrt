#!/bin/sh
set -eu

REPO="Unay1/roamd-openwrt"
RAW="https://raw.githubusercontent.com/$REPO/main"
FEED_BASE="https://github.com/$REPO/releases/download"
FEED_TAG="feed-25.12-aarch64_cortex-a53"
ARCH="aarch64_cortex-a53"
TARGET="mediatek/filogic"

msg() { printf '\033[32;1m%s\033[0m\n' "$1"; }
err() { printf '\033[31;1m%s\033[0m\n' "$1" >&2; }

fail() {
    err "$1"
    exit 1
}

check_system() {
    [ -f /etc/openwrt_release ] || fail "Это не OpenWrt."
    . /etc/openwrt_release

    case "${DISTRIB_RELEASE:-}" in
        25.12.*) ;;
        *) fail "Поддерживается OpenWrt 25.12.x; обнаружена ${DISTRIB_RELEASE:-неизвестная версия}." ;;
    esac

    [ "${DISTRIB_TARGET:-}" = "$TARGET" ] ||
        fail "Эта сборка предназначена для target $TARGET; обнаружен ${DISTRIB_TARGET:-неизвестный target}."

    [ "${DISTRIB_ARCH:-}" = "$ARCH" ] ||
        fail "Неподдерживаемая архитектура: ${DISTRIB_ARCH:-неизвестно}; требуется $ARCH."

    command -v apk >/dev/null 2>&1 || fail "Не найден apk. Эта сборка рассчитана на OpenWrt 25.12 с APK."

    msg "Устройство: $(cat /tmp/sysinfo/model 2>/dev/null || echo неизвестно)"
    msg "OpenWrt $DISTRIB_RELEASE; $TARGET; $ARCH"
}

check_conflicts() {
    installed=$(apk list --installed 2>/dev/null || true)

    for p in usteer dawn; do
        if printf '%s\n' "$installed" | grep -q "^$p-"; then
            fail "Обнаружен пакет $p. Одновременно запускать его вместе с roamd не следует. Удаление не выполнялось; сначала выберите один менеджер роуминга."
        fi
    done
}

install_key() {
    mkdir -p /etc/apk/keys
    tmp="/tmp/roamd-apk.pem."$

    wget -q -O "$tmp" "$RAW/keys/roamd-apk.pem" ||
        fail "Не удалось получить публичный ключ подписи roamd-openwrt."

    [ -s "$tmp" ] || fail "Скачанный публичный ключ пуст."
    mv "$tmp" /etc/apk/keys/roamd-apk.pem
    msg "Ключ подписи установлен."
}

configure_feed() {
    conf="/etc/apk/repositories.d/roamd.list"
    feed="$FEED_BASE/$FEED_TAG/packages.adb"

    mkdir -p /etc/apk/repositories.d
    printf '%s\n' "$feed" > "$conf"
    msg "Репозиторий настроен: $feed"
}

main() {
    check_system
    check_conflicts

    msg "Подключаем подписанный репозиторий."
    install_key
    configure_feed

    apk update || fail "Не удалось обновить индексы APK. Проверьте доступность официальных репозиториев OpenWrt и интернет-соединение."

    msg "Устанавливаем или обновляем roamd, LuCI и русский перевод."
    apk add roamd luci-app-roamd luci-i18n-roamd-ru ||
        fail "Установка пакетов не удалась."

    [ -x /etc/init.d/roamd ] || fail "Пакет установлен, но init-скрипт /etc/init.d/roamd не найден."

    /etc/init.d/roamd enable
    /etc/init.d/roamd restart

    msg "Готово. Откройте LuCI → Сеть → Роуминг Wi-Fi."
}

main "$@"
