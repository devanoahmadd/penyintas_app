const { initializeApp } = require('firebase-admin/app');
const { setGlobalOptions } = require('firebase-functions');

initializeApp();

setGlobalOptions({ maxInstances: 10, region: 'asia-southeast2' });

const { dailyReminder } = require('./daily_reminder');
const { budgetWarning } = require('./budget_warning');
const { paydayReminder } = require('./payday_reminder');
const { generateInsight } = require('./insights');

module.exports = { dailyReminder, budgetWarning, paydayReminder, generateInsight };
