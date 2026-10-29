/* ============================================================================
 * rvkqqVPN — Unbihex Rust Core C-FFI Bridging Header (unbihex_ffi.h)
 * Author & License: rvkqq (All Rights Reserved / MIT Dual License)
 * Bundle Targets: com.rvkqq.vpn & com.rvkqq.vpn.tunnel
 * ============================================================================ */

#ifndef UNBIHEX_FFI_H
#define UNBIHEX_FFI_H

#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Starts the Unbihex Rust packet processor bound to the iOS NEPacketTunnelProvider
 * kernel utun file descriptor.
 *
 * @param tun_fd Kernel utun file descriptor (>0)
 * @param config_json_ptr Null-terminated UTF-8 JSON configuration string
 * @return 0 on success, negative error code on failure
 */
int32_t unbihex_instance_start(int32_t tun_fd, const char *config_json_ptr);

/**
 * Performs a zero-drop atomic hot reload (Instance::reload) of the active Unbihex
 * instance without closing the kernel utun file descriptor or dropping sockets.
 *
 * @param new_config_json_ptr Null-terminated UTF-8 JSON configuration string
 * @return Positive reload generation number on success, negative on error
 */
int32_t unbihex_instance_reload(const char *new_config_json_ptr);

/**
 * Gracefully stops the Unbihex Rust engine and flushes ring buffers.
 *
 * @return 0 on success, -1 if already stopped
 */
int32_t unbihex_instance_stop(void);

/**
 * Returns the current Unbihex allocator memory footprint in bytes (capped <18MB).
 */
uint64_t unbihex_get_memory_bytes(void);

/**
 * Invoked by the Swift mach_task_basic_info watchdog. If resident_bytes approaches
 * the 18MB (18,874,368 B) ceiling, compacts XMUX and Succinct Trie caches immediately.
 *
 * @return 1 if emergency compaction was triggered, 0 if nominal
 */
int32_t unbihex_enforce_memory_guard(uint64_t resident_bytes);

/**
 * Returns a heap-allocated JSON string with real-time Unbihex telemetry,
 * XUDP GlobalID, TLS fragmentation state, and memory metrics.
 * Caller must free with unbihex_free_string().
 */
char *unbihex_get_telemetry_json(void);

/**
 * Frees a C string allocated by the Unbihex Rust core.
 */
void unbihex_free_string(char *ptr);

#ifdef __cplusplus
}
#endif

#endif /* UNBIHEX_FFI_H */
