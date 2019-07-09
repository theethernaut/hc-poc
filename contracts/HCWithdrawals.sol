pragma solidity ^0.5.0;

import "./HCCompensations.sol";

contract HCWithdrawals is HCCompensations {
    
    function withdrawStakeFromExpiredQueuedProposal(uint256 _proposalId) public {
        require(_proposalExists(_proposalId), ERROR_PROPOSAL_DOES_NOT_EXIST);
        require(_proposalStateIs(_proposalId, ProposalState.Expired), ERROR_PROPOSAL_IS_ACTIVE);

        // Require the proposal's state to not be resolved or boosted.
        Proposal storage proposal_ = proposals[_proposalId];
        // TODO: This changed, it needs to be expired
        require(proposal_.state != ProposalState.Resolved);
        require(proposal_.state != ProposalState.Boosted);

        // Calculate the amount of that the user has staked.
        uint256 senderUpstake = proposal_.upstakes[msg.sender];
        uint256 senderDownstake = proposal_.downstakes[msg.sender];
        uint256 senderTotalStake = senderUpstake.add(senderDownstake);
        require(senderTotalStake > 0, ERROR_NO_STAKE_TO_WITHDRAW);

        // Callculate the staker's final payout, by subtracting the
        // expiration call fee proportionally to the amount of stake that the user made.
        // TODO: fee might change by this time, better to store it in the proposal data structure
        uint256 compensationFee = _calculateCompensationFee(_proposalId);
        uint256 totalStake = proposal_.upstake.add(proposal_.downstake);
        uint256 senderTotalStakeRatio = senderTotalStake.mul(PRECISION_MULTIPLIER) / totalStake;
        uint256 senderFeeContribution = senderTotalStakeRatio.mul(compensationFee) / PRECISION_MULTIPLIER;
        uint256 payout = senderTotalStake.sub(senderFeeContribution);

        // Remove the stake from the proposal.
        // TODO: Remove this because the next withdrawer would obtain different values
        // proposal_.upstake = proposal_.upstake.sub(upstake);
        // proposal_.downstake = proposal_.downstake.sub(downstake);

        // Remove the stake from the sender.
        proposal_.upstakes[msg.sender] = 0;
        proposal_.downstakes[msg.sender] = 0;

        // Return the tokens to the sender.
        require(stakeToken.balanceOf(address(this)) >= payout, ERROR_VOTING_DOES_NOT_HAVE_ENOUGH_FUNDS);
        stakeToken.transfer(msg.sender, payout);

    }

    // TODO: What about proposals that are resolved with abs maj? Review doc
    function withdrawRewardFromResolvedBoostedProposal(uint256 _proposalId) public {
        require(_proposalExists(_proposalId), ERROR_PROPOSAL_DOES_NOT_EXIST);
        require(_proposalStateIs(_proposalId, ProposalState.Resolved), ERROR_PROPOSAL_IS_ACTIVE);
        require(_proposalStateIs(_proposalId, ProposalState.Boosted), ERROR_PROPOSAL_IS_NOT_BOOSTED);

        // Get proposal outcome.
        Proposal storage proposal_ = proposals[_proposalId];
        bool supported = proposal_.yea > proposal_.nay;

        // Retrieve the sender's winning stake.
        uint256 winningStake = supported ? proposal_.upstakes[msg.sender] : proposal_.downstakes[msg.sender];
        require(winningStake > 0, ERROR_NO_WINNING_STAKE);

        // Calculate the sender's reward.
        // TODO: see same case above, this could change
        uint256 compensationFee = _calculateCompensationFee(_proposalId);
        uint256 totalWinningStake = supported ? proposal_.upstake : proposal_.downstake;
        uint256 totalLosingStake = supported ? proposal_.downstake : proposal_.upstake;
        totalLosingStake = totalLosingStake.sub(compensationFee);
        uint256 sendersWinningRatio = winningStake.mul(PRECISION_MULTIPLIER) / totalWinningStake;
        uint256 reward = sendersWinningRatio.mul(totalLosingStake) / PRECISION_MULTIPLIER;
        uint256 total = winningStake.add(reward);

        // Transfer the tokens to the winner.
        require(stakeToken.balanceOf(address(this)) >= total, ERROR_VOTING_DOES_NOT_HAVE_ENOUGH_FUNDS);
        stakeToken.transfer(msg.sender, total);
    }
}