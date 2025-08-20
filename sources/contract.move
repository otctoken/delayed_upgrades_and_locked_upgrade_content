module policy::delayed_upgrades_and_locked_upgrade_content{

    use sui::package;
    use sui::clock::{Clock};
    // Day is not a week day (number in range 0 <= day < 7).
    const MS_IN_DAY: u64 = 48 * 60 * 60 * 1000;//修改为1000


    public struct Policy has key, store {
        id: UID,
        cap: package::UpgradeCap,
    }
    public struct Proposal has key, store {
        id: UID,
        digest: vector<u8>,
        eta_ms: u64,
    }

    fun init(ctx: &mut TxContext) {
        let v = vector::empty<u8>();
        let p = Proposal { id: object::new(ctx),digest:v,eta_ms:0};
        transfer::public_transfer(p, ctx.sender());
    }


    public entry fun new_policy(
        cap: package::UpgradeCap,
        ctx: &mut TxContext,
    ){
        transfer::public_transfer(Policy { id: object::new(ctx), cap }, ctx.sender());
    }

    public entry fun init_ploy(
        pro:&mut Proposal,
        digest:vector<u8>, 
        clk: &Clock,
    ){
        pro.eta_ms = clk.timestamp_ms() + MS_IN_DAY;
        pro.digest = digest;
    }
    public fun authorize_upgrade(
        cap:&mut Policy,
        pro:&mut Proposal,
        clk: &Clock,
        ctx: &TxContext,
    ): package::UpgradeTicket {
        assert!(pro.eta_ms > 0, 0);
        assert!(pro.eta_ms < clk.timestamp_ms(), 1);
        pro.eta_ms = 0;
        cap.cap.authorize_upgrade(0, pro.digest)
    }

    public fun commit_upgrade(
        cap: &mut Policy,
        receipt: package::UpgradeReceipt,
    ) {
        cap.cap.commit_upgrade(receipt)
    }

    public fun make_immutable(cap: Policy) {
        let Policy { id, cap } = cap;
        id.delete();
        cap.make_immutable()
    }

}
