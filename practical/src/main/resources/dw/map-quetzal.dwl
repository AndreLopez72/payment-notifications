%dw 2.0
import * from dw::Crypto
import toHex from dw::core::Binaries
output application/json

var providerEvent = payload
var charge = providerEvent.data.charge
var providerState = providerEvent.type
var canonicalStatus =
    if (providerState == "charge.succeeded") "captured"
    else if (providerState == "charge.failed") "failed"
    else if (providerState == "charge.refunded") "refunded"
    else null
var stateChangedAtEpoch =
    if (providerState == "charge.succeeded") charge.paid_at default providerEvent.created
    else if (providerState == "charge.refunded") charge.refunded_at default providerEvent.created
    else providerEvent.created
var transactionId = charge.id as String
---
{
    schemaVersion: "1.0",
    eventId: "MX:Quetzal:" ++ (providerEvent.id as String),
    country: "MX",
    provider: "Quetzal",
    providerEventId: providerEvent.id as String,
    providerTransactionId: transactionId,
    paymentKey: "MX:Quetzal:" ++ lower(toHex(Crypto::hashWith(transactionId as Binary, "SHA-256"))),
    policyNumber: upper(charge.reference as String),
    status: canonicalStatus,
    amount: ((charge.amount as Number) / 100) as String {format: "0.00"},
    refundedAmount:
        if (providerState == "charge.refunded")
            ((charge.amount_refunded as Number) / 100) as String {format: "0.00"}
        else null,
    currency: upper(charge.currency as String),
    stateChangedAt: ((stateChangedAtEpoch as DateTime {unit: "seconds"}) >> "UTC"),
    receivedAt: ((vars.receivedAt as DateTime) >> "UTC"),
    correlationId: vars.correlationId as String
}
