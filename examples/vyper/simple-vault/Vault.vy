# @version ^0.3.9

"""
@title Simple Vault
@notice A basic vault contract for depositing and withdrawing ETH
@dev Demonstrates Vyper syntax and patterns
"""

# Events
event Deposit:
    depositor: indexed(address)
    amount: uint256
    timestamp: uint256

event Withdrawal:
    recipient: indexed(address)
    amount: uint256
    timestamp: uint256

event OwnershipTransferred:
    previousOwner: indexed(address)
    newOwner: indexed(address)

# State variables
owner: public(address)
balances: public(HashMap[address, uint256])
totalDeposits: public(uint256)
minDeposit: public(uint256)
paused: public(bool)

@external
def __init__():
    """
    @notice Contract constructor
    @dev Sets the deployer as the initial owner
    """
    self.owner = msg.sender
    self.minDeposit = as_wei_value(0.01, "ether")
    self.paused = False

@external
@payable
def deposit():
    """
    @notice Deposit ETH into the vault
    @dev Requires minimum deposit amount and contract not paused
    """
    assert not self.paused, "Contract is paused"
    assert msg.value >= self.minDeposit, "Deposit below minimum"

    self.balances[msg.sender] += msg.value
    self.totalDeposits += msg.value

    log Deposit(msg.sender, msg.value, block.timestamp)

@external
def withdraw(amount: uint256):
    """
    @notice Withdraw ETH from the vault
    @param amount Amount to withdraw in wei
    @dev Only allows withdrawing up to deposited balance
    """
    assert not self.paused, "Contract is paused"
    assert self.balances[msg.sender] >= amount, "Insufficient balance"

    self.balances[msg.sender] -= amount
    self.totalDeposits -= amount

    send(msg.sender, amount)

    log Withdrawal(msg.sender, amount, block.timestamp)

@external
def withdrawAll():
    """
    @notice Withdraw entire balance
    @dev Convenience function to withdraw all deposited funds
    """
    amount: uint256 = self.balances[msg.sender]
    assert amount > 0, "No balance to withdraw"
    assert not self.paused, "Contract is paused"

    self.balances[msg.sender] = 0
    self.totalDeposits -= amount

    send(msg.sender, amount)

    log Withdrawal(msg.sender, amount, block.timestamp)

@view
@external
def getBalance(account: address) -> uint256:
    """
    @notice Get balance of an account
    @param account Address to query
    @return Balance in wei
    """
    return self.balances[account]

@view
@external
def getContractBalance() -> uint256:
    """
    @notice Get total contract balance
    @return Contract balance in wei
    """
    return self.balance

@external
def setMinDeposit(newMinDeposit: uint256):
    """
    @notice Set minimum deposit amount (owner only)
    @param newMinDeposit New minimum deposit in wei
    """
    assert msg.sender == self.owner, "Only owner"
    self.minDeposit = newMinDeposit

@external
def setPaused(pausedState: bool):
    """
    @notice Pause or unpause contract (owner only)
    @param pausedState True to pause, False to unpause
    """
    assert msg.sender == self.owner, "Only owner"
    self.paused = pausedState

@external
def transferOwnership(newOwner: address):
    """
    @notice Transfer ownership to new address
    @param newOwner Address of new owner
    @dev Only current owner can transfer ownership
    """
    assert msg.sender == self.owner, "Only owner"
    assert newOwner != empty(address), "Invalid address"

    oldOwner: address = self.owner
    self.owner = newOwner

    log OwnershipTransferred(oldOwner, newOwner)

@external
def emergencyWithdraw():
    """
    @notice Emergency withdrawal for owner
    @dev Allows owner to withdraw all funds in emergency
    """
    assert msg.sender == self.owner, "Only owner"
    send(self.owner, self.balance)
