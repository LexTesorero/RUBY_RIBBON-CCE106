/// Cash is allowed only for IMMEDIATE pickup/delivery.
/// For modular and bespoke items, staff can confirm the cash only after
/// accepting (approving) the order, i.e. once its status leaves "received".
bool isCashAllowed({required bool isImmediate}) => isImmediate;

/// Customers can cancel only before baking/decorating starts (status
/// 'received'), for standard, modular and bespoke orders. For modular/bespoke,
/// "the baker accepts" = the status moves past 'received'.
bool canCustomerCancel({required String status}) => status == 'received';