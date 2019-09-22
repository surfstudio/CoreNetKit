import Foundation

/// Модель для внутреннего представления multipart запроса.
public struct MultipartUrlRequest {

    /// HTTP метод.
    public let method: Method
    /// URL эндпоинта.
    public let url: URL
    /// Хедеры запроса.
    public let headers: [String: String]
    /// Данные для запроса.
    public let data: MultipartModel<[String: Data]>

    public init(method: Method,
                url: URL,
                headers: [String: String],
                data: MultipartModel<[String: Data]>) {
        self.method = method
        self.url = url
        self.headers = headers
        self.data = data
    }
}

/// Узел, умеющий создавать multipart-запрос.
open class MultipartRequestCreatorNode<Output>: Node<MultipartUrlRequest, Output> {
    /// Следующий узел для обработки.
    public var next: Node<RawUrlRequest, Output>

    /// Инициаллизирует узел.
    ///
    /// - Parameter next: Следующий узел для обработки.
    public init(next: Node<RawUrlRequest, Output>) {
        self.next = next
    }

    /// Конфигурирует низкоуровненвый запрос.
    ///
    /// - Parameter data: Данные для конфигурирования и последующей отправки запроса.
    open override func process(_ data: MultipartUrlRequest) -> Observer<Output> {
        let manager = ServerRequestsManager.shared.manager

        let request = manager.upload(multipartFormData: { (multipartForm) in
            data.data.payloadModel.forEach { key, value in
                multipartForm.append(value, withName: key)
            }
        }, to: data.url, method: data.method.http, headers: .init(data.headers))

        return self.next.process(RawUrlRequest(dataRequest: request)).log(self.getLogMessage(data))
    }

    private func getLogMessage(_ data: MultipartUrlRequest) -> Log {
        var message = "<<<===\(self.objectName)===>>>\n"
        message += "input: \(type(of: data))\n\t"
        message += "method: \(data.method.http.rawValue)\n\t"
        message += "url: \(data.url.absoluteString)\n\t"
        message += "headers: \(data.headers)\n\t"
        message += "parametersEncoding: multipart)"

        return Log(message, id: self.objectName, order: LogOrder.requestCreatorNode)
    }
}