import Route from "discourse/routes/discourse";
import { ajax } from "discourse/lib/ajax";
export default class AdminDiscourseVipSepayPlansRoute extends Route { model() { return Promise.all([ajax("/admin/vip-sepay/plans.json"), ajax("/admin/vip-sepay/groups.json")]).then(([plans, groups]) => ({ ...plans, ...groups })); } }
