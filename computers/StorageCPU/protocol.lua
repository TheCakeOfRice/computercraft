local protocol = {
    SERVICE = "cc-storage/v1",
    DISCOVERY_HOST = "main",
    PROVISION = "cc-storage-provision/v1",
}

function protocol.reply(request, ok, result, err)
    return {
        kind = "response",
        requestId = request.requestId,
        ok = ok,
        result = result,
        error = err,
    }
end

return protocol
