const fs = require('fs');
const filePath = 'C:/Website Project/EMapandan_V2/EMapandan/app/api/mobile/mayor/dashboard/route.ts';

let content = fs.readFileSync(filePath, 'utf8');

const targetStr = `        // Process Daily Revenue Analytics Chart
        const dailyPayMap = new Map<string, number>();
        const currP = new Date(payFromDate);
        while (currP <= payToDate) {
            dailyPayMap.set(getPhilippineDateString(currP), 0);
            currP.setDate(currP.getDate() + 1);
        }

        let totalPayRevenue = 0;
        payments.forEach((p) => {
            totalPayRevenue += p.amount;
            const dStr = getPhilippineDateString(p.createdAt);
            if (dailyPayMap.has(dStr)) {
                dailyPayMap.set(dStr, dailyPayMap.get(dStr)! + p.amount);
            }
        });

        const revenueChartData = Array.from(dailyPayMap.entries()).map(([dStr, total]) => {
            const parts = dStr.split("-");
            const dObj = new Date(parseInt(parts[0], 10), parseInt(parts[1], 10) - 1, parseInt(parts[2], 10));
            return {
                date: getPhilippineDisplayString(dObj),
                total,
            };
        });`;

const replacementStr = `        // Process Daily Revenue Analytics Chart with Category Breakdown
        const dailyPayMap = new Map<string, { total: number; categories: Record<string, number> }>();
        const currP = new Date(payFromDate);
        while (currP <= payToDate) {
            dailyPayMap.set(getPhilippineDateString(currP), { total: 0, categories: {} });
            currP.setDate(currP.getDate() + 1);
        }

        let totalPayRevenue = 0;
        payments.forEach((p) => {
            totalPayRevenue += p.amount;
            const dStr = getPhilippineDateString(p.createdAt);
            const category = p.transaction?.type?.category || "OTHER";

            if (dailyPayMap.has(dStr)) {
                const entry = dailyPayMap.get(dStr)!;
                entry.total += p.amount;
                entry.categories[category] = (entry.categories[category] || 0) + p.amount;
            }
        });

        const revenueChartData = Array.from(dailyPayMap.entries()).map(([dStr, data]) => {
            const parts = dStr.split("-");
            const dObj = new Date(parseInt(parts[0], 10), parseInt(parts[1], 10) - 1, parseInt(parts[2], 10));
            return {
                date: getPhilippineDisplayString(dObj),
                total: data.total,
                categories: data.categories,
            };
        });`;

// Normalize carriage returns
const normalizedContent = content.replace(/\r\n/g, '\n');
const normalizedTarget = targetStr.replace(/\r\n/g, '\n');
const normalizedReplacement = replacementStr.replace(/\r\n/g, '\n');

if (normalizedContent.includes(normalizedTarget)) {
    const updated = normalizedContent.replace(normalizedTarget, normalizedReplacement);
    fs.writeFileSync(filePath, updated, 'utf8');
    console.log('SUCCESS');
} else {
    console.log('NOT_FOUND');
}
