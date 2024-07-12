public without sharing class CustomCartFee {
    private static final String CART_FEE_PRODUCT_SKU = 'CART_FEE';
    private static final Decimal CART_FEE_PRICE = 0.5;

    public CustomCartFee() {
    }

    private Product2 getCartFeeProduct() {
        return [SELECT Id, StockKeepingUnit, Name FROM Product2 WHERE StockKeepingUnit = :CART_FEE_PRODUCT_SKU LIMIT 1];
    }

    private CartExtension.CartItem createFeeCartItem(CartExtension.CartDeliveryGroup deliveryGroup) {
        Product2 feeProduct = getCartFeeProduct();
        CartExtension.CartItem item = new CartExtension.CartItem(CartExtension.SalesItemTypeEnum.CHARGE, deliveryGroup, feeProduct.Name);
        item.setProduct2Id(feeProduct.Id);
        item.setQuantity(1);
        item.setSku(feeProduct.StockKeepingUnit);
        item.setGrossUnitPrice(CART_FEE_PRICE);
        item.setSalesPrice(CART_FEE_PRICE);
        item.setTotalListPrice(CART_FEE_PRICE);
        item.setTotalPrice(CART_FEE_PRICE);
        item.setTotalLineAmount(CART_FEE_PRICE);
        return item;
    }

    private Boolean isFeeApplicable(CartExtension.Cart cart, CartExtension.CartDeliveryGroup deliveryGroup) {
        Address shippingAddress = deliveryGroup.getDeliverToAddress();
        String state = shippingAddress.getState();
        Decimal merchandizeTotal = cart.getTotalProductAmount();
        // minnesota state and product amount is greater or equal to 100
        return merchandizeTotal >= 100 && state == 'MN';
    }

    private CartExtension.CartItem getPreviouslyAppliedFeeItem(CartExtension.CartItemList allItems) {
        Integer len = allItems.size();
        for (Integer i = 0; i < len; i++) {
            CartExtension.CartItem item = (CartExtension.CartItem) allItems.get(i);
            if (item.getSku() == CART_FEE_PRODUCT_SKU) {
                return item;
            }
        }
        return null;
    }

    public void applyFee(CartExtension.Cart cart) {
        CartExtension.CartDeliveryGroupList cartDeliveryGroups = cart.getCartDeliveryGroups();
        // for now we only focus on single shipment scenarios
        CartExtension.CartDeliveryGroup deliveryGroup = (CartExtension.CartDeliveryGroup) cartDeliveryGroups.get(0);
        CartExtension.CartItemList allItems = cart.getCartItems();

        if (!isFeeApplicable(cart, deliveryGroup)) {
            CartExtension.CartItem item = getPreviouslyAppliedFeeItem(allItems);
            // remove existing fee item if applied
            if (item != null) {
                allItems.remove(item);
            }
            return;
        }

        CartExtension.CartItem feeItem = createFeeCartItem(deliveryGroup);
        allItems.add(feeItem);
    }

    public void setTotalAmountForFeeOrderItem(List<OrderItem> orderItems) {
        Product2 feeProduct = getCartFeeProduct();
        for (OrderItem orderItem : orderItems) {
            if (orderItem.Product2Id == feeProduct.Id) {
                orderItem.TotalLineAmount = CART_FEE_PRICE;
            }
        }
    }
}
