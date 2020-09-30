import 'package:dio/dio.dart' as dio;
import '../network_event.dart';
import '../network_logger.dart';

class DioNetworkLogger extends dio.Interceptor {
  final NetworkEventList eventList;

  DioNetworkLogger({NetworkEventList eventList})
      : this.eventList = eventList ?? NetworkLogger.instance;

  Map<dio.RequestOptions, NetworkEvent> _requests;

  @override
  Future onRequest(dio.RequestOptions options) {
    var event = NetworkEvent.request(options.toRequest());
    eventList.add(_requests[options] = event);
    return Future.value(options);
  }

  @override
  Future onResponse(dio.Response response) {
    var event = _requests[response.request];
    if (event != null) {
      event.response = response.toResponse();
      eventList.updated(event);
    } else {
      eventList.add(NetworkEvent.response(response.toResponse()));
    }
    return Future.value(response);
  }

  @override
  Future onError(dio.DioError err) {
    var event = _requests[err.request];
    if (event != null) {
      event.error = NetworkError(
        request: event.request,
        response: err.response?.toResponse(),
        message: err.toString(),
      );
      eventList.updated(event);
    } else {
      eventList.add(NetworkEvent.error(NetworkError(
        request: err.request.toRequest(),
        response: err.response?.toResponse(),
        message: err.toString(),
      )));
    }
    return Future.value(err);
  }
}

extension _RequestOptionsX on dio.RequestOptions {
  Request toRequest() => Request(
        uri: uri.toString(),
        data: data,
        method: method,
        headers: Headers.fromMap(headers.map(
          (key, value) => MapEntry(key, '$value'),
        )),
      );
}

extension _ResponseX on dio.Response {
  Response toResponse() => Response(
        data: data,
        headers: Headers(headers.map.entries.fold(
          [],
          (p, e) => p..addAll(e.value.map((v) => MapEntry(e.key, v))),
        )),
      );
}
