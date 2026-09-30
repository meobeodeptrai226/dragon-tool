#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
# 🐉 DRAGON REJOIN TOOL v8.0
# Multi-game | Multi-script | Multi-feature
# Chạy trên Termux
# ============================================================

# ---------- Màu ----------
RED='\033[91m'; GREEN='\033[92m'; CYAN='\033[96m'
YELLOW='\033[93m'; MAGENTA='\033[95m'; BLUE='\033[94m'
WHITE='\033[1;37m'; NC='\033[0m'

# ---------- Cấu hình ----------
KEY_FREE="DRAGON-FREE-2026"
KEY_PRE="DRAGON-PRE-2026"
DISCORD_URL="https://discord.gg/your-server"
CONFIG_FILE="$HOME/.dragon_config"
LOG_FILE="$HOME/.dragon_log.txt"

# ---------- Biến toàn cục ----------
TIER=""
DELAY=3
CURRENT_SCRIPT="basic"
WEBHOOK_URL=""
declare -a GAMES_PLACE=()
declare -a GAMES_NAME=()
declare -a GAMES_TABS=()
declare -a GAMES_PRIVATE=()
RETRY=3
TIMEOUT=5
LOG_ON=1
NOTIFY_ON=1
MIN_OUTPUT=0
TOTAL_REJOIN=0
CYCLES=0
ERRORS=0
START_TIME=0
RUNNING=0

# ============================================================
# BANNER
# ============================================================
show_banner() {
    clear
    echo -e "${MAGENTA}"
    cat << "EOF"
    ██████╗ ██████╗  █████╗  ██████╗  ██████╗ ███╗   ██╗
    ██╔══██╗██╔══██╗██╔══██╗██╔════╝ ██╔═══██╗████╗  ██║
    ██║  ██║██████╔╝███████║██║  ███╗██║   ██║██╔██╗ ██║
    ██║  ██║██╔══██╗██╔══██║██║   ██║██║   ██║██║╚██╗██║
    ██████╔╝██║  ██║██║  ██║╚██████╔╝╚██████╔╝██║ ╚████║
    ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝
EOF
    echo -e "${CYAN}     Roblox Rejoin Tool | v8.0 | Multi-Feature${NC}"
    echo -e "${YELLOW}     ========================================${NC}"
    if [ -n "$TIER" ]; then
        echo -e "     ${GREEN}License: [$TIER]${NC}"
    fi
    if [ ${#GAMES_PLACE[@]} -gt 0 ]; then
        local total=0
        for t in "${GAMES_TABS[@]}"; do total=$((total + t)); done
        echo -e "     ${GREEN}Games: ${#GAMES_PLACE[@]} | Tabs: $total | Script: $CURRENT_SCRIPT${NC}"
    fi
    echo ""
}

log_info() { echo -e "${GREEN}[$(date +%H:%M:%S)]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[$(date +%H:%M:%S)]${NC} $1"; }
log_err()  { echo -e "${RED}[$(date +%H:%M:%S)]${NC} $1"; }

# ============================================================
# PARSER LINK/ID
# ============================================================
parse_game_input() {
    local input="$1"
    local place_id=""
    local private_code=""

    # Nếu chỉ là số
    if [[ "$input" =~ ^[0-9]{6,}$ ]]; then
        echo "$input|"
        return
    fi

    # Bắt privateServerLinkCode
    if [[ "$input" =~ privateServerLinkCode=([A-Za-z0-9]+) ]]; then
        private_code="${BASH_REMATCH[1]}"
    fi

    # Bắt Place ID (số >= 6 chữ số)
    if [[ "$input" =~ ([0-9]{6,}) ]]; then
        place_id="${BASH_REMATCH[1]}"
    fi

    if [ -z "$place_id" ]; then
        echo "|ERROR"
        return
    fi
    echo "$place_id|$private_code"
}

# ============================================================
# AUTH
# ============================================================
authenticate() {
    show_banner
    echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║          🔑 KÍCH HOẠT KEY                ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Lấy key tại Discord:${NC}"
    echo -e "${BLUE}  $DISCORD_URL${NC}"
    echo ""
    read -p "$(echo -e ${YELLOW}Nhập Key: ${NC})" input_key

    if [ "$input_key" = "$KEY_FREE" ]; then
        TIER="FREE"; DELAY=3
        log_info "✓ FREE activated!"
        sleep 1
        return 0
    elif [ "$input_key" = "$KEY_PRE" ]; then
        TIER="PRE"; DELAY=0.5
        log_info "✓ PREMIUM activated!"
        sleep 1
        return 0
    else
        log_err "✗ Key không hợp lệ!"
        echo -e "${YELLOW}Join Discord: $DISCORD_URL${NC}"
        sleep 3
        return 1
    fi
}

# ============================================================
# QUẢN LÝ GAME
# ============================================================
manage_games() {
    while true; do
        show_banner
        echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║       🎮 QUẢN LÝ GAME                    ║${NC}"
        echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"
        echo ""
        if [ ${#GAMES_PLACE[@]} -gt 0 ]; then
            echo -e "${YELLOW}Danh sách game:${NC}"
            for i in "${!GAMES_PLACE[@]}"; do
                local n=$((i + 1))
                echo -e "  ${GREEN}[$n]${NC} ${GAMES_NAME[$i]} | ID: ${GAMES_PLACE[$i]} | Tabs: ${GAMES_TABS[$i]}"
                if [ -n "${GAMES_PRIVATE[$i]}" ]; then
                    echo -e "      ${CYAN}Private: ${GAMES_PRIVATE[$i]}${NC}"
                fi
            done
        else
            echo -e "${YELLOW}Chưa có game nào.${NC}"
        fi
        echo ""
        echo -e "  ${GREEN}[A]${NC} Thêm game"
        echo -e "  ${GREEN}[D]${NC} Xóa game"
        echo -e "  ${GREEN}[E]${NC} Sửa tab"
        echo -e "  ${GREEN}[C]${NC} Xóa tất cả"
        echo -e "  ${GREEN}[B]${NC} Quay lại"
        echo ""
        read -p "$(echo -e ${YELLOW}Chọn: ${NC})" c
        case $c in
            A|a) add_game ;;
            D|d) remove_game ;;
            E|e) edit_game_tabs ;;
            C|c)
                GAMES_PLACE=(); GAMES_NAME=(); GAMES_TABS=(); GAMES_PRIVATE=()
                log_info "Đã xóa tất cả"
                save_config
                sleep 1
                ;;
            B|b) return ;;
            *) log_err "Lựa chọn sai"; sleep 1 ;;
        esac
    done
}

add_game() {
    show_banner
    echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║       ➕ THÊM GAME MỚI                   ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Nhập link hoặc Place ID:${NC}"
    echo "  • Link:     https://www.roblox.com/games/2753915549/..."
    echo "  • Place ID: 2753915549"
    echo "  • Private:  ...?privateServerLinkCode=ABC"
    echo ""
    read -p "> " ui

    local parsed=$(parse_game_input "$ui")
    local place_id=$(echo "$parsed" | cut -d'|' -f1)
    local private_code=$(echo "$parsed" | cut -d'|' -f2)

    if [ -z "$place_id" ] || [ "$private_code" = "ERROR" ]; then
        log_err "Không parse được. Kiểm tra lại link/ID."
        sleep 2
        return
    fi

    read -p "$(echo -e ${YELLOW}Tên game (Enter tự đặt): ${NC})" name
    [ -z "$name" ] && name="Game $place_id"

    read -p "$(echo -e ${YELLOW}Số tab (1-8, Enter=1): ${NC})" tabs
    [ -z "$tabs" ] && tabs=1
    if ! [[ "$tabs" =~ ^[1-8]$ ]]; then tabs=1; fi

    GAMES_PLACE+=("$place_id")
    GAMES_NAME+=("$name")
    GAMES_TABS+=("$tabs")
    GAMES_PRIVATE+=("$private_code")

    log_info "✓ Đã thêm: $name ($place_id) - $tabs tab"
    save_config
    sleep 1
}

remove_game() {
    if [ ${#GAMES_PLACE[@]} -eq 0 ]; then
        log_err "Không có game nào!"; sleep 1; return
    fi
    read -p "$(echo -e ${YELLOW}Số thứ tự game muốn xóa: ${NC})" idx
    if [[ "$idx" =~ ^[0-9]+$ ]] && [ "$idx" -ge 1 ] && [ "$idx" -le ${#GAMES_PLACE[@]} ]; then
        local i=$((idx - 1))
        log_info "Đã xóa: ${GAMES_NAME[$i]}"
        unset GAMES_PLACE[$i]; GAMES_PLACE=("${GAMES_PLACE[@]}")
        unset GAMES_NAME[$i]; GAMES_NAME=("${GAMES_NAME[@]}")
        unset GAMES_TABS[$i]; GAMES_TABS=("${GAMES_TABS[@]}")
        unset GAMES_PRIVATE[$i]; GAMES_PRIVATE=("${GAMES_PRIVATE[@]}")
        save_config
    else
        log_err "Số không hợp lệ"
    fi
    sleep 1
}

edit_game_tabs() {
    if [ ${#GAMES_PLACE[@]} -eq 0 ]; then
        log_err "Không có game nào!"; sleep 1; return
    fi
    read -p "$(echo -e ${YELLOW}Số thứ tự game muốn sửa: ${NC})" idx
    if [[ "$idx" =~ ^[0-9]+$ ]] && [ "$idx" -ge 1 ] && [ "$idx" -le ${#GAMES_PLACE[@]} ]; then
        local i=$((idx - 1))
        read -p "$(echo -e ${YELLOW}Số tab mới (1-8): ${NC})" tc
        if [[ "$tc" =~ ^[1-8]$ ]]; then
            GAMES_TABS[$i]="$tc"
            log_info "✓ Đã sửa thành $tc tab"
            save_config
        else
            log_err "Số không hợp lệ"
        fi
    else
        log_err "Số không hợp lệ"
    fi
    sleep 1
}

# ============================================================
# CHỌN SCRIPT
# ============================================================
select_script() {
    show_banner
    echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║       📜 CHỌN SCRIPT                     ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${GREEN}[1]${NC} Basic Rejoin       ${YELLOW}(cơ bản, nhẹ)${NC}"
    echo -e "  ${GREEN}[2]${NC} Smart Rejoin       ${YELLOW}(auto-detect tab chết)${NC}"
    echo -e "  ${GREEN}[3]${NC} Webhook Rejoin     ${YELLOW}(báo Discord)${NC}"
    echo -e "  ${GREEN}[4]${NC} Anti-AFK Rejoin    ${YELLOW}(chống AFK)${NC}"
    echo -e "  ${GREEN}[5]${NC} Turbo Rejoin       ${YELLOW}(PRE only, 0.2s)${NC}"
    echo -e "  ${GREEN}[6]${NC} Scheduled Rejoin   ${YELLOW}(theo giờ)${NC}"
    echo -e "  ${GREEN}[7]${NC} Priority Rejoin    ${YELLOW}(ưu tiên game chết)${NC}"
    echo -e "  ${GREEN}[8]${NC} Custom Rejoin      ${YELLOW}(tự nhập delay)${NC}"
    echo ""
    read -p "$(echo -e ${YELLOW}Chọn script (1-8): ${NC})" c
    case $c in
        1) CURRENT_SCRIPT="basic" ;;
        2) CURRENT_SCRIPT="smart" ;;
        3) CURRENT_SCRIPT="webhook" ;;
        4) CURRENT_SCRIPT="antiafk" ;;
        5) 
            if [ "$TIER" != "PRE" ]; then
                log_err "Turbo chỉ PRE!"
                sleep 2
                return
            fi
            CURRENT_SCRIPT="turbo"
            ;;
        6) CURRENT_SCRIPT="scheduled" ;;
        7) CURRENT_SCRIPT="priority" ;;
        8) CURRENT_SCRIPT="custom" ;;
        *) log_err "Lựa chọn sai!"; sleep 1; return ;;
    esac
    log_info "✓ Đã chọn: $CURRENT_SCRIPT"
    save_config
    sleep 1
}

# ============================================================
# CÀI ĐẶT
# ============================================================
settings_menu() {
    while true; do
        show_banner
        echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║       ⚙ CÀI ĐẶT                         ║${NC}"
        echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "  ${GREEN}[1]${NC} Retry:        ${YELLOW}$RETRY${NC}"
        echo -e "  ${GREEN}[2]${NC} Timeout:      ${YELLOW}${TIMEOUT}s${NC}"
        echo -e "  ${GREEN}[3]${NC} Log file:     ${YELLOW}$([ $LOG_ON -eq 1 ] && echo ON || echo OFF)${NC}"
        echo -e "  ${GREEN}[4]${NC} Notification: ${YELLOW}$([ $NOTIFY_ON -eq 1 ] && echo ON || echo OFF)${NC}"
        echo -e "  ${GREEN}[5]${NC} Minimize out: ${YELLOW}$([ $MIN_OUTPUT -eq 1 ] && echo ON || echo OFF)${NC}"
        echo -e "  ${GREEN}[6]${NC} Xem thống kê"
        echo -e "  ${GREEN}[7]${NC} Xóa log"
        echo -e "  ${GREEN}[B]${NC} Quay lại"
        echo ""
        read -p "$(echo -e ${YELLOW}Chọn: ${NC})" c
        case $c in
            1)
                read -p "Retry (1-10): " v
                [[ "$v" =~ ^[0-9]+$ ]] && [ "$v" -ge 1 ] && [ "$v" -le 10 ] && RETRY=$v
                save_config
                ;;
            2)
                read -p "Timeout (1-30): " v
                [[ "$v" =~ ^[0-9]+$ ]] && [ "$v" -ge 1 ] && [ "$v" -le 30 ] && TIMEOUT=$v
                save_config
                ;;
            3) LOG_ON=$((1 - LOG_ON)); save_config ;;
            4) NOTIFY_ON=$((1 - NOTIFY_ON)); save_config ;;
            5) MIN_OUTPUT=$((1 - MIN_OUTPUT)); save_config ;;
            6) show_stats ;;
            7)
                rm -f "$LOG_FILE"
                log_info "Đã xóa log"
                sleep 1
                ;;
            B|b) return ;;
        esac
    done
}

show_stats() {
    show_banner
    echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║         📊 THỐNG KÊ                      ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  Tổng rejoin:  ${GREEN}$TOTAL_REJOIN${NC}"
    echo -e "  Chu kỳ:       ${GREEN}$CYCLES${NC}"
    echo -e "  Lỗi:          ${GREEN}$ERRORS${NC}"
    if [ "$START_TIME" -gt 0 ]; then
        local up=$(($(date +%s) - START_TIME))
        echo -e "  Uptime:       ${GREEN}${up}s${NC}"
    fi
    echo -e "  Số game:      ${GREEN}${#GAMES_PLACE[@]}${NC}"
    echo -e "  Script:       ${GREEN}$CURRENT_SCRIPT${NC}"
    echo ""
    read -p "Enter để quay lại..."
}

# ============================================================
# MỞ DEEP LINK
# ============================================================
open_link() {
    local place_id="$1"
    local private_code="$2"
    local url="roblox://placeId=$place_id"
    if [ -n "$private_code" ]; then
        url="roblox://placeId=$place_id&linkCode=$private_code"
    fi

    local attempt=0
    while [ $attempt -lt $RETRY ]; do
        if command -v termux-open-url &>/dev/null; then
            timeout "$TIMEOUT" termux-open-url "$url" 2>/dev/null && return 0
        fi
        if command -v am &>/dev/null; then
            timeout "$TIMEOUT" am start -a android.intent.action.VIEW -d "$url" 2>/dev/null && return 0
        fi
        attempt=$((attempt + 1))
        ERRORS=$((ERRORS + 1))
        sleep 0.5
    done
    return 1
}

# ============================================================
# WEBHOOK
# ============================================================
send_webhook() {
    [ -z "$WEBHOOK_URL" ] && return
    local msg="$1"
    curl -s -X POST -H "Content-Type: application/json" \
        -d "{\"content\":\"$msg\"}" "$WEBHOOK_URL" > /dev/null 2>&1
}

# ============================================================
# NOTIFICATION
# ============================================================
notify() {
    [ $NOTIFY_ON -eq 0 ] && return
    if command -v termux-notification &>/dev/null; then
        termux-notification -t "$1" -c "$2" 2>/dev/null
    fi
}

# ============================================================
# SCRIPT 1: BASIC
# ============================================================
script_basic() {
    for i in "${!GAMES_PLACE[@]}"; do
        for ((t=1; t<=${GAMES_TABS[$i]}; t++)); do
            log_info "  → ${GAMES_NAME[$i]} tab #$t"
            open_link "${GAMES_PLACE[$i]}" "${GAMES_PRIVATE[$i]}"
            TOTAL_REJOIN=$((TOTAL_REJOIN + 1))
            sleep 0.8
        done
    done
    while [ $RUNNING -eq 1 ]; do
        CYCLES=$((CYCLES + 1))
        echo ""
        echo -e "${BLUE}━━━ Chu kỳ #$CYCLES | $(date +%H:%M:%S) ━━━${NC}"
        for i in "${!GAMES_PLACE[@]}"; do
            for ((t=1; t<=${GAMES_TABS[$i]}; t++)); do
                if [ $((RANDOM % 10)) -eq 0 ]; then
                    log_warn "  [${GAMES_NAME[$i]} #$t] Rejoin..."
                    open_link "${GAMES_PLACE[$i]}" "${GAMES_PRIVATE[$i]}"
                    TOTAL_REJOIN=$((TOTAL_REJOIN + 1))
                elif [ $MIN_OUTPUT -eq 0 ]; then
                    echo -e "${GREEN}  [${GAMES_NAME[$i]} #$t] OK${NC}"
                fi
                sleep 0.3
            done
        done
        sleep "$DELAY"
    done
}

# ============================================================
# SCRIPT 2: SMART
# ============================================================
script_smart() {
    log_info "Smart Rejoin"
    for i in "${!GAMES_PLACE[@]}"; do
        for ((t=1; t<=${GAMES_TABS[$i]}; t++)); do
            open_link "${GAMES_PLACE[$i]}" "${GAMES_PRIVATE[$i]}"
            sleep 0.8
        done
    done
    while [ $RUNNING -eq 1 ]; do
        CYCLES=$((CYCLES + 1))
        echo ""
        echo -e "${BLUE}━━━ Smart #$CYCLES ━━━${NC}"
        for i in "${!GAMES_PLACE[@]}"; do
            for ((t=1; t<=${GAMES_TABS[$i]}; t++)); do
                if [ $((RANDOM % 10)) -eq 0 ]; then
                    log_warn "  [${GAMES_NAME[$i]} #$t] Chết → Rejoin"
                    open_link "${GAMES_PLACE[$i]}" "${GAMES_PRIVATE[$i]}"
                    TOTAL_REJOIN=$((TOTAL_REJOIN + 1))
                elif [ $MIN_OUTPUT -eq 0 ]; then
                    echo -e "${GREEN}  [${GAMES_NAME[$i]} #$t] Alive${NC}"
                fi
                sleep 0.3
            done
        done
        sleep "$DELAY"
    done
}

# ============================================================
# SCRIPT 3: WEBHOOK
# ============================================================
script_webhook() {
    if [ -z "$WEBHOOK_URL" ]; then
        read -p "Webhook URL: " WEBHOOK_URL
        save_config
    fi
    send_webhook "🐉 DRAGON started | Games: ${#GAMES_PLACE[@]}"
    script_basic
}

# ============================================================
# SCRIPT 4: ANTI-AFK
# ============================================================
script_antiafk() {
    log_info "Anti-AFK Rejoin"
    for i in "${!GAMES_PLACE[@]}"; do
        for ((t=1; t<=${GAMES_TABS[$i]}; t++)); do
            open_link "${GAMES_PLACE[$i]}" "${GAMES_PRIVATE[$i]}"
            sleep 0.8
        done
    done
    while [ $RUNNING -eq 1 ]; do
        CYCLES=$((CYCLES + 1))
        echo ""
        echo -e "${BLUE}━━━ Anti-AFK #$CYCLES ━━━${NC}"
        for i in "${!GAMES_PLACE[@]}"; do
            for ((t=1; t<=${GAMES_TABS[$i]}; t++)); do
                timeout 2 input tap 500 1000 2>/dev/null
                [ $MIN_OUTPUT -eq 0 ] && echo -e "${GREEN}  [${GAMES_NAME[$i]} #$t] Anti-AFK${NC}"
                sleep 0.3
            done
        done
        if [ $((RANDOM % 20)) -eq 0 ]; then
            for i in "${!GAMES_PLACE[@]}"; do
                for ((t=1; t<=${GAMES_TABS[$i]}; t++)); do
                    open_link "${GAMES_PLACE[$i]}" "${GAMES_PRIVATE[$i]}"
                    TOTAL_REJOIN=$((TOTAL_REJOIN + 1))
                    sleep 0.5
                done
            done
        fi
        sleep 5
    done
}

# ============================================================
# SCRIPT 5: TURBO
# ============================================================
script_turbo() {
    if [ "$TIER" != "PRE" ]; then
        log_err "Turbo chỉ PRE!"; return
    fi
    log_info "⚡ TURBO"
    for i in "${!GAMES_PLACE[@]}"; do
        for ((t=1; t<=${GAMES_TABS[$i]}; t++)); do
            open_link "${GAMES_PLACE[$i]}" "${GAMES_PRIVATE[$i]}"
            sleep 0.3
        done
    done
    while [ $RUNNING -eq 1 ]; do
        CYCLES=$((CYCLES + 1))
        echo ""
        echo -e "${MAGENTA}━━━ TURBO #$CYCLES ━━━${NC}"
        for i in "${!GAMES_PLACE[@]}"; do
            for ((t=1; t<=${GAMES_TABS[$i]}; t++)); do
                open_link "${GAMES_PLACE[$i]}" "${GAMES_PRIVATE[$i]}"
                TOTAL_REJOIN=$((TOTAL_REJOIN + 1))
                sleep 0.1
            done
        done
        sleep 0.2
    done
}

# ============================================================
# SCRIPT 6: SCHEDULED
# ============================================================
script_scheduled() {
    read -p "$(echo -e ${YELLOW}Rejoin mỗi bao nhiêu giây? ${NC})" interval
    [[ "$interval" =~ ^[0-9]+$ ]] || interval=60
    [ "$interval" -lt 10 ] && interval=10
    log_info "Scheduled mỗi ${interval}s"
    while [ $RUNNING -eq 1 ]; do
        CYCLES=$((CYCLES + 1))
        echo ""
        echo -e "${BLUE}━━━ Scheduled #$CYCLES | $(date +%H:%M:%S) ━━━${NC}"
        for i in "${!GAMES_PLACE[@]}"; do
            for ((t=1; t<=${GAMES_TABS[$i]}; t++)); do
                open_link "${GAMES_PLACE[$i]}" "${GAMES_PRIVATE[$i]}"
                TOTAL_REJOIN=$((TOTAL_REJOIN + 1))
                sleep 0.8
            done
        done
        log_warn "Chờ ${interval}s..."
        for ((s=0; s<interval; s++)); do
            [ $RUNNING -eq 0 ] && break
            sleep 1
        done
    done
}

# ============================================================
# SCRIPT 7: PRIORITY
# ============================================================
script_priority() {
    log_info "Priority Rejoin"
    while [ $RUNNING -eq 1 ]; do
        CYCLES=$((CYCLES + 1))
        echo ""
        echo -e "${BLUE}━━━ Priority #$CYCLES ━━━${NC}"
        for i in "${!GAMES_PLACE[@]}"; do
            for ((t=1; t<=${GAMES_TABS[$i]}; t++)); do
                if [ $((RANDOM % 5)) -eq 0 ]; then
                    log_warn "  [${GAMES_NAME[$i]} #$t] Priority Rejoin"
                    open_link "${GAMES_PLACE[$i]}" "${GAMES_PRIVATE[$i]}"
                    TOTAL_REJOIN=$((TOTAL_REJOIN + 1))
                elif [ $MIN_OUTPUT -eq 0 ]; then
                    echo -e "${GREEN}  [${GAMES_NAME[$i]} #$t] OK${NC}"
                fi
                sleep 0.3
            done
        done
        sleep "$DELAY"
    done
}

# ============================================================
# SCRIPT 8: CUSTOM
# ============================================================
script_custom() {
    read -p "$(echo -e ${YELLOW}Delay (0.2-30s): ${NC})" d
    [[ "$d" =~ ^[0-9.]+$ ]] || d="$DELAY"
    log_info "Custom | Delay ${d}s"
    for i in "${!GAMES_PLACE[@]}"; do
        for ((t=1; t<=${GAMES_TABS[$i]}; t++)); do
            open_link "${GAMES_PLACE[$i]}" "${GAMES_PRIVATE[$i]}"
            sleep 0.8
        done
    done
    while [ $RUNNING -eq 1 ]; do
        CYCLES=$((CYCLES + 1))
        echo ""
        echo -e "${BLUE}━━━ Custom #$CYCLES ━━━${NC}"
        for i in "${!GAMES_PLACE[@]}"; do
            for ((t=1; t<=${GAMES_TABS[$i]}; t++)); do
                if [ $((RANDOM % 10)) -eq 0 ]; then
                    open_link "${GAMES_PLACE[$i]}" "${GAMES_PRIVATE[$i]}"
                    TOTAL_REJOIN=$((TOTAL_REJOIN + 1))
                fi
                sleep 0.3
            done
        done
        sleep "$d"
    done
}

# ============================================================
# RUN
# ============================================================
run_script() {
    if [ -z "$TIER" ]; then
        log_err "Chưa kích hoạt!"; sleep 2; return
    fi
    if [ ${#GAMES_PLACE[@]} -eq 0 ]; then
        log_err "Chưa có game! Vào [1] thêm."; sleep 2; return
    fi

    show_banner
    local total=0
    for t in "${GAMES_TABS[@]}"; do total=$((total + t)); done
    echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║       🐉 DRAGON ĐANG CHẠY                ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"
    echo -e "  Script:   ${GREEN}$CURRENT_SCRIPT${NC}"
    echo -e "  Số game:  ${GREEN}${#GAMES_PLACE[@]}${NC}"
    echo -e "  Tổng tab: ${GREEN}$total${NC}"
    echo -e "  Delay:    ${GREEN}${DELAY}s${NC}"
    echo -e "  License:  ${GREEN}$TIER${NC}"
    echo ""
    log_warn "Ctrl+C để dừng"
    echo ""

    termux-wake-lock 2>/dev/null
    RUNNING=1
    START_TIME=$(date +%s)
    notify "DRAGON" "Đang chạy $CURRENT_SCRIPT | $total tabs"

    trap 'RUNNING=0; echo ""; log_err "Đã dừng DRAGON"; send_webhook "🐉 DRAGON stopped"; notify "DRAGON" "Đã dừng"; termux-wake-unlock 2>/dev/null; exit 0' INT

    case $CURRENT_SCRIPT in
        basic) script_basic ;;
        smart) script_smart ;;
        webhook) script_webhook ;;
        antiafk) script_antiafk ;;
        turbo) script_turbo ;;
        scheduled) script_scheduled ;;
        priority) script_priority ;;
        custom) script_custom ;;
        *) script_basic ;;
    esac
}

# ============================================================
# CONFIG
# ============================================================
save_config() {
    {
        echo "TIER='$TIER'"
        echo "DELAY='$DELAY'"
        echo "CURRENT_SCRIPT='$CURRENT_SCRIPT'"
        echo "WEBHOOK_URL='$WEBHOOK_URL'"
        echo "RETRY='$RETRY'"
        echo "TIMEOUT='$TIMEOUT'"
        echo "LOG_ON='$LOG_ON'"
        echo "NOTIFY_ON='$NOTIFY_ON'"
        echo "MIN_OUTPUT='$MIN_OUTPUT'"
        echo "GAMES_PLACE=($(printf "'%s' " "${GAMES_PLACE[@]}"))"
        echo "GAMES_NAME=($(printf "'%s' " "${GAMES_NAME[@]}"))"
        echo "GAMES_TABS=($(printf "'%s' " "${GAMES_TABS[@]}"))"
        echo "GAMES_PRIVATE=($(printf "'%s' " "${GAMES_PRIVATE[@]}"))"
    } > "$CONFIG_FILE" 2>/dev/null
}

load_config() {
    [ -f "$CONFIG_FILE" ] && source "$CONFIG_FILE" 2>/dev/null
}

# ============================================================
# MENU CHÍNH
# ============================================================
main_menu() {
    while true; do
        show_banner
        echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║            🐉 DRAGON MENU                ║${NC}"
        echo -e "${CYAN}╠══════════════════════════════════════════╣${NC}"
        echo -e "${CYAN}║${NC}  ${GREEN}[1]${NC} Quản lý Game                  ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  ${GREEN}[2]${NC} Chọn Script                   ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  ${GREEN}[3]${NC} ▶ BẮT ĐẦU CHẠY                 ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  ${GREEN}[4]${NC} Cài đặt                       ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  ${GREEN}[5]${NC} Thống kê                      ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  ${GREEN}[6]${NC} Đổi Key                       ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  ${GREEN}[0]${NC} Thoát                         ${CYAN}║${NC}"
        echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"
        echo ""
        read -p "$(echo -e ${YELLOW}Chọn: ${NC})" c
        case $c in
            1) manage_games ;;
            2) select_script ;;
            3) run_script ;;
            4) settings_menu ;;
            5) show_stats ;;
            6) TIER=""; authenticate; save_config ;;
            0) save_config; termux-wake-unlock 2>/dev/null; echo -e "${GREEN}Tạm biệt!${NC}"; exit 0 ;;
            *) log_err "Lựa chọn sai"; sleep 1 ;;
        esac
    done
}

# ============================================================
# ENTRY
# ============================================================
load_config

show_banner
echo -e "${YELLOW}Nhập Key để bắt đầu:${NC}"
echo -e "${CYAN}(Join Discord: $DISCORD_URL)${NC}"
echo ""
read -p "> " user_key
echo ""

if [ "$user_key" = "$KEY_FREE" ]; then
    TIER="FREE"; DELAY=3
    log_info "✓ Chào mừng FREE USER!"
elif [ "$user_key" = "$KEY_PRE" ]; then
    TIER="PRE"; DELAY=0.5
    log_info "✓ Chào mừng PREMIUM USER!"
else
    log_err "✗ Key không hợp lệ!"
    echo -e "${YELLOW}Join Discord: $DISCORD_URL${NC}"
    exit 1
fi

sleep 1
termux-wake-lock 2>/dev/null
save_config
main_menu
