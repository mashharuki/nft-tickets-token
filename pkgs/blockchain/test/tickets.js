const Tickets = artifacts.require("Tickets");

/*
 * uncomment accounts to access the test accounts made available by the
 * Ethereum client
 * See docs: https://www.trufflesuite.com/docs/truffle/testing/writing-tests-in-javascript
 */
contract("Tickets", function (/* accounts */) {
  it("should assert true", async function () {
    await Tickets.deployed();
    return assert.isTrue(true);
  });
});
