const { query } = require('../database');
const { EMPTY_RESULT_ERROR, SQL_ERROR_CODE, UNIQUE_VIOLATION_ERROR } = require('../errors');

const { PrismaClient, Prisma } = require('@prisma/client');

const prisma = new PrismaClient();

module.exports.retrieveAll = async function (filters) {
    const {
        status,
        minOrderDatetime,
        maxOrderDatetime,
        minQuantity,
        maxQuantity,
        searchProductDescription,
        minUnitPrice,
        maxUnitPrice,
        username,
        minDob,
        maxDob,
        sortOrder
    } = filters;

    // Initialize filter conditions
    const filterConditions = [];

    // Adding conditions based on provided filters
    if (status) {
        filterConditions.push({ status: { in: status.split(',') } });
    }
    if (minOrderDatetime) {
        filterConditions.push({ orderDatetime: { gte: new Date(minOrderDatetime) } });
    }
    if (maxOrderDatetime) {
        filterConditions.push({ orderDatetime: { lte: new Date(maxOrderDatetime) } });
    }
    if (username) {
        filterConditions.push({ member: { username: { contains: username, mode: 'insensitive' } } });
    }
    if (minDob) {
        filterConditions.push({ member: { dob: { gte: new Date(minDob) } } });
    }
    if (maxDob) {
        filterConditions.push({ member: { dob: { lte: new Date(maxDob) } } });
    }

    // Product filters within saleOrderItem
    const productConditions = [];
    if (searchProductDescription) {
        productConditions.push({
            description: { contains: searchProductDescription.trim(), mode: 'insensitive' }
        });
    }
    if (minUnitPrice) {
        productConditions.push({ unitPrice: { gte: parseFloat(minUnitPrice) } });
    }
    if (maxUnitPrice) {
        productConditions.push({ unitPrice: { lte: parseFloat(maxUnitPrice) } });
    }

    const where = {
        AND: filterConditions,
        saleOrderItem: {
            some: {
                quantity: {
                    gte: minQuantity ? parseInt(minQuantity) : undefined,
                    lte: maxQuantity ? parseInt(maxQuantity) : undefined,
                },
                product: productConditions.length ? { AND: productConditions } : undefined,
            },
        },
    };

    const saleOrders = await prisma.saleOrder.findMany({
        where,
        orderBy: { orderDatetime: sortOrder || 'asc' },
        include: {
            saleOrderItem: {
                include: {
                    product: true,
                },
            },
            member: true,
        },
    });

    // Filtering records
    let filteredSaleOrders = saleOrders.reduce((acc, order) => {
        const matchedItems = order.saleOrderItem.filter(item => {
            return (!minUnitPrice || item.product.unitPrice >= parseFloat(minUnitPrice)) &&
                   (!maxUnitPrice || item.product.unitPrice <= parseFloat(maxUnitPrice)) &&
                   (!minQuantity || item.quantity >= parseInt(minQuantity)) &&
                   (!maxQuantity || item.quantity <= parseInt(maxQuantity));
        });

        return acc.concat(matchedItems.map(item => ({
            name: item.product?.name || '',
            description: item.product?.description || '',
            unitPrice: parseFloat(item.product?.unitPrice) || 0,
            quantity: item.quantity,
            country: item.product?.country || '',
            imageUrl: item.product?.imageUrl || '/default-image.png',
            saleOrderId: order.id,
            orderDatetime: order.orderDatetime.toISOString(),
            status: order.status,
            productType: item.product?.productType || '',
            username: order.member?.username || '',
        })));
    }, []);

    return filteredSaleOrders;
};
