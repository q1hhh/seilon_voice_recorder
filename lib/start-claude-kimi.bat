@echo off
title Claude + Kimi K2.5

REM ===== Proxy =====
set HTTP_PROXY=http://127.0.0.1:7890
set HTTPS_PROXY=http://127.0.0.1:7890
set ALL_PROXY=socks5://127.0.0.1:7890

REM ===== Kimi API =====
set ANTHROPIC_AUTH_TOKEN=sk-kimi-JVghwU8mNVzHiM8DFgcuQkIxL0ShKFPrTE5awGIeb65BqPTEzlRKMfA0P4DlaHUn
set ANTHROPIC_BASE_URL=https://api.kimi.com/coding/

REM ===== 最新模型 =====
set ANTHROPIC_MODEL=kimi-for-coding
set ANTHROPIC_DEFAULT_OPUS_MODEL=kimi-for-coding
set ANTHROPIC_DEFAULT_SONNET_MODEL=kimi-for-coding

claude
pause