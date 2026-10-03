import Route from "discourse/routes/discourse";
import { ajax } from "discourse/lib/ajax";
export default class AdminDiscourseVipSepayTransactionsRoute extends Route { model() { return ajax("/admin/vip-sepay/transactions.json"); } }
