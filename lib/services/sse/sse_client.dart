/// SSE 客户端 — 条件导出入口
/// Web 编译时使用 sse_client_web.dart（dart:html）
/// 原生编译时使用 sse_client_native.dart（dart:io + Dio）
///
/// 两个平台文件各自导出一个具体的 SseClient 类
export 'sse_client_native.dart'
    if (dart.library.html) 'sse_client_web.dart';
