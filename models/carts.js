const { query } = require('../database');
const { EMPTY_RESULT_ERROR, SQL_ERROR_CODE, UNIQUE_VIOLATION_ERROR } = require('../errors');
const { PrismaClient, Prisma } = require('@prisma/client');

const prisma = new PrismaClient();

module.exports.createSingleCartItem = function createSingleCartItem(memberId, productId, quantity) {
    return prisma.cartItem.create({
    data: {
        memberId: memberId,
        productId: parseInt(productId),
        quantity: parseInt(quantity)
    }
    }).then(function (cartItem) {
    return cartItem;
    }).catch(function (error) {
        if (error instanceof Prisma.PrismaClientKnownRequestError) {
            if (error.code === 'P2002') {
                throw new Error(`The item ${productId} is not found!`);
            }
        }
        throw error;
    });
}

module.exports.retrieveAll = function retrieveAll(memberId) {
    // Return all cart items for a specific member
    return prisma.cartItem.findMany({
        where: {
            memberId: memberId
        },
        include: {
            product: true
        }
    }).then(function (cartItems) {
        return cartItems;
    });
};

module.exports.updateSingleCartItem = function updateSingleCartItem(memberId, id, quantity) {
    return prisma.cartItem.update({
        where: {
            memberId: memberId,
            id: parseInt(id)
        },
        data: {
            quantity: parseInt(quantity)
        }
    }).then(function (cartItem) {
        return cartItem;
    }).catch(function (error) {
        // Handle Prisma Error, throw a new error if item is not found                             
        if (error instanceof Prisma.PrismaClientKnownRequestError) {
            if (error.code === 'P2025') {
                throw new Error(`The item ${id} is not found!`);
            }
        }
        throw error;    
    });
};

module.exports.deleteSingleCartItem = function deleteSingleCartItem(memberId, id) {
    return prisma.cartItem.delete({
        where: {
            memberId: memberId,
            id: parseInt(id)
        }
    }).then(function (cartItem) {
        return cartItem;
    }).catch(function (error) {
        // Handle Prisma Error, throw a new error if item is not found                             
        if (error instanceof Prisma.PrismaClientKnownRequestError) {
            if (error.code === 'P2025') {
                throw new Error(`The Item ${id} is not found!`);
            }
        }
        throw error;
    })
};

module.exports.createMultipleCartItems = function createMultipleCartItems(memberId, cartItemsList) {
    // Parse the cartItemsList and attach memberId to each item
    const data = cartItemsList.map(item => ({
        ...item,
        memberId: memberId
    }));
    
    return prisma.cartItem.createMany({
        data: data
    }).then(function (result) {
        return result;
    }).catch(function (error) {
        throw error;
    });
};

module.exports.updateMultipleCartItems = async function updateMultipleCartItems(memberId, cartItems) {
    const updatePromises = cartItems.map((item) => {
        return prisma.cartItem.updateMany({
            where: {
                memberId_id: {  // Composite unique identifier, if memberId and id together are unique
                    memberId: memberId,
                    id: parseInt(item.id),
                }
            },
            data: {
                quantity: parseInt(item.quantity),
            },
        });
    });

    return Promise.all(updatePromises)
        .then((updatedItems) => {
            return updatedItems;
        })
        .catch((error) => {
            throw error;
        });
};

module.exports.getCartSummary = function getCartSummary(memberId) {
    return prisma.cartItem.findMany({
        where: { memberId: memberId },
        include: { product: true }
    }).then(cartItems => {
        const totalQuantity = cartItems.reduce((acc, item) => acc + item.quantity, 0);
        const totalPrice = cartItems.reduce((acc, item) => acc + item.quantity * item.product.unitPrice, 0);
        const uniqueProductIds = new Set(cartItems.map(item => item.productId));
        const totalProduct = uniqueProductIds.size;

        return {
            totalQuantity,
            totalPrice,
            totalProduct
        };
    });
};