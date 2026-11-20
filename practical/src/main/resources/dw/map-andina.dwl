%dw 2.0
import * from dw::Crypto
import toHex from dw::core::Binaries
output application/json

var providerEvent = payload
var transaction = providerEvent.transaccion
var providerState = transaction.estado
var canonicalStatus =
    if (providerState == "PENDIENTE") "pending"
    else if (providerState == "APROBADA") "captured"
    else if (providerState == "RECHAZADA") "failed"
    else if (providerState == "REVERSADA") "refunded"
    else null
var transactionId = transaction.id as String
---
{
    schemaVersion: "1.0",
    eventId: "CO:Andina:" ++ transactionId ++ ":" ++ (providerState as String),
    country: "CO",
    provider: "Andina",
    providerEventId: providerEvent.notificacion_id as String,
    providerTransactionId: transactionId,
    paymentKey: "CO:Andina:" ++ lower(toHex(Crypto::hashWith(transactionId as Binary, "SHA-256"))),
    policyNumber: upper(transaction.referencia as String),
    status: canonicalStatus,
    amount: transaction.valor as String,
    refundedAmount: null,
    currency: upper(transaction.moneda as String),
    stateChangedAt: ((transaction.fecha_transaccion as DateTime) >> "UTC"),
    receivedAt: ((vars.receivedAt as DateTime) >> "UTC"),
    correlationId: vars.correlationId as String
}
