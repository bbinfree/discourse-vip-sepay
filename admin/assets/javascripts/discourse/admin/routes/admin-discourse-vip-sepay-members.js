import Route from "discourse/routes/discourse";
import { ajax } from "discourse/lib/ajax";
export default class AdminDiscourseVipSepayMembersRoute extends Route { model() { return ajax("/admin/vip-sepay/members.json"); } }
