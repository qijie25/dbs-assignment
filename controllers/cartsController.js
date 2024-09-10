const { EMPTY_RESULT_ERROR, UNIQUE_VIOLATION_ERROR } = require('../errors');
const cartsModel = require('../models/carts');

module.exports.createSingleCartItem = function (req, res) {
    const memberId = res.locals.member_id;
    const productId = req.body.productId;
    const quantity = req.body.quantity;

    return cartsModel
        .createSingleCartItem(memberId, productId, quantity)
        .then(function () {
            return res.sendStatus(201);
        })
        .catch(function (error) {
            console.error(error);
            if (error instanceof UNIQUE_VIOLATION_ERROR) {
                return res.status(400).json({ error: error.message });
            }
            return res.status(500).json({ error: error.message });
        });
}

module.exports.updateSingleCartItem = function (req, res) {
    const memberId = res.locals.member_id;
    const id = req.params.id;
    const quantity = req.body.quantity;
    return cartsModel
        .updateSingleCartItem(memberId, id, quantity)
        .then(function () {
            console.log("update ok!");
            return res.status(200).json({ msg: "updated!" });
        })
        .catch(function (error) {
            console.error(error);
            if (error instanceof EMPTY_RESULT_ERROR) {
                return res.status(404).json({ error: error.message });
            }
            return res.status(500).json({ error: error.message });
        });
}

module.exports.deleteSingleCartItem = function (req, res) {
    // Delete Item by Id
    const memberId = res.locals.member_id;
    const id = req.params.id;
    return cartsModel
        .deleteSingleCartItem(memberId,id)
        .then(function () {
            console.log("delete ok!");
            return res.status(200).json({ msg: "deleted!" });
        })
        .catch(function (error) {
            console.error(error);
            if (error instanceof EMPTY_RESULT_ERROR) {
                // return res.status(404).json({ error: error.message });
                return res.status(404).json({ error: "No such Item!" });
            }
            return res.status(500).json({ error: error.message });
        });
}

module.exports.getAllCartItems = function (req, res) {
    const memberId = res.locals.member_id;

    return cartsModel
        .retrieveAll(memberId)
        .then(function (cartItems) {
            return res.json({ cartItems: cartItems });
        })
        .catch(function (error) {
            console.error(error);
            return res.status(500).json({ error: error.message });
        });
}

module.exports.createMultipleCartItems = function (req, res) {
    const memberId = res.locals.member_id;
    const cartItemsList = req.body.cartItemsList;

    return cartsModel
        .createMultipleCartItems(memberId, cartItemsList)
        .then(function (result) {
            return res.status(201).json({ msg: `${result.count} cart items created!` });
        })
        .catch(function (error) {
            console.error(error);
            return res.status(500).json({ error: error.message });
        });
};

module.exports.updateMultipleCartItems = function (req, res) {
    const memberId = res.locals.member_id;
    const cartItems = req.body.cartItems;

    if (!Array.isArray(cartItems) || cartItems.length === 0) {
        return res.status(400).json({ error: 'No items to update' });
    }

    return cartsModel
        .updateMultipleCartItems(memberId, cartItems)
        .then(function (updatedItems) {
            console.log("Update multiple items successful!");
            return res.status(200).json({ msg: "Updated multiple items!", updatedItems });
        })
        .catch(function (error) {
            console.error(error);
            return res.status(500).json({ error: error.message });
        });
};

module.exports.getCartSummary = function (req, res) {
    const memberId = res.locals.member_id;

    return cartsModel
        .getCartSummary(memberId)
        .then(function (cartSummary) {
            return res.json({ cartSummary: cartSummary });
        })
        .catch(function (error) {
            console.error(error);
            return res.status(500).json({ error: error.message });
        });
};