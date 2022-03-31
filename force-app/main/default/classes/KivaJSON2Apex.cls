public class KivaJSON2Apex {

	public Integer total_records;
	public List<Data> data;

	public class Data {
		public Integer borrower_count;
		public String internal_loan_id;
		public String internal_client_id;
		public String partner_id;
		public String partner;
		public String kiva_id;
		public String uuid;
		public String name;
		public String location;
		public String status;
		public String status_detail;
		public String loan_price;
		public String loan_local_price;
		public String loan_currency;
		public String create_time;
		public String ended_time;
		public String refunded_time;
		public String expired_time;
		public String defaulted_time;
		public String planned_expiration_time;
		public String planned_inactive_expire_time;
		public Boolean delinquent;
		public String issue_feedback_time;
		public String issue_reported_by;
		public String flexible_fundraising_enabled;
		public String fundedAmount;
	}

	
	public static KivaJSON2Apex parse(String json) {
		return (KivaJSON2Apex) System.JSON.deserialize(json, KivaJSON2Apex.class);
	}
}