<<<<<<< Updated upstream
# @version ^0.3.7

struct Comment:
    id: uint256
    content: String[500]
    timestamp: uint256
    author: address
    is_truly_anonymous: bool
    is_revealed: bool

owner: public(address)
fee_recipient: public(address)
comment_fee: public(uint256)
reveal_fee: public(uint256)
true_anonymity_fee: public(uint256)

whitelist: public(HashMap[address, bool])
comments: public(HashMap[uint256, Comment])
comment_count: public(uint256)

event CommentPosted:
    comment_id: indexed(uint256)
    timestamp: uint256

event CommentRevealed:
    comment_id: indexed(uint256)
    author: address
    revealer: address

@external
def __init__(_comment_fee: uint256, _reveal_fee: uint256, _true_anonymity_fee: uint256):
    """
    @notice Initialize the Secrasay contract
    @param _comment_fee Fee to post a comment (in wei)
    @param _reveal_fee Fee to reveal a commenter's identity (in wei)
    @param _true_anonymity_fee Additional fee for true anonymity (in wei)
    """
    self.owner = msg.sender
    # Set your address as the fee recipient
    self.fee_recipient = 0xf237c60E7eEF0Bb688A6ED0423828B5a92Dc8452
    self.comment_fee = _comment_fee
    self.reveal_fee = _reveal_fee
    self.true_anonymity_fee = _true_anonymity_fee
    self.comment_count = 0
    # Add contract owner to whitelist
    self.whitelist[msg.sender] = True

@external
def add_to_whitelist(user: address):
    """
    @notice Add a user to the whitelist
    @param user Address to whitelist
    """
    assert msg.sender == self.owner, "Only owner can whitelist users"
    self.whitelist[user] = True

@external
def remove_from_whitelist(user: address):
    """
    @notice Remove a user from the whitelist
    @param user Address to remove from whitelist
    """
    assert msg.sender == self.owner, "Only owner can remove users from whitelist"
    self.whitelist[user] = False

@external
@payable
def post_comment(content: String[500], want_true_anonymity: bool):
    """
    @notice Post a comment by paying the required fee
    @param content The comment text
    @param want_true_anonymity Whether the user wants true anonymity
    """
    # Check if user is whitelisted
    assert self.whitelist[msg.sender], "User is not whitelisted"
    
    # Calculate required fee
    required_fee: uint256 = self.comment_fee
    if want_true_anonymity:
        required_fee += self.true_anonymity_fee
    
    # Check if enough ETH was sent
    assert msg.value >= required_fee, "Insufficient fee"
    
    # Create the comment
    comment_id: uint256 = self.comment_count
    self.comments[comment_id] = Comment({
        id: comment_id,
        content: content,
        timestamp: block.timestamp,
        author: msg.sender,
        is_truly_anonymous: want_true_anonymity,
        is_revealed: False
    })
    
    # Increment comment count
    self.comment_count += 1
    
    # Send fee to fee recipient (your address)
    send(self.fee_recipient, msg.value)
    
    # Emit event
    log CommentPosted(comment_id, block.timestamp)

@external
@payable
def reveal_commenter(comment_id: uint256):
    """
    @notice Pay to reveal a commenter's identity
    @param comment_id The ID of the comment to reveal
    """
    # Check if comment exists
    assert comment_id < self.comment_count, "Comment does not exist"
    
    # Check if the comment is not already revealed
    assert not self.comments[comment_id].is_revealed, "Comment already revealed"
    
    # Check if the comment is truly anonymous
    assert not self.comments[comment_id].is_truly_anonymous, "Comment is truly anonymous and cannot be revealed"
    
    # Check if enough ETH was sent
    assert msg.value >= self.reveal_fee, "Insufficient fee"
    
    # Mark comment as revealed
    self.comments[comment_id].is_revealed = True
    
    # Send fee to fee recipient (your address)
    send(self.fee_recipient, msg.value)
    
    # Emit event
    log CommentRevealed(comment_id, self.comments[comment_id].author, msg.sender)

@external
@view
def get_comment(comment_id: uint256) -> (String[500], uint256, address, bool):
    """
    @notice Get details of a comment
    @param comment_id The ID of the comment
    @return content, timestamp, author (if revealed), is_truly_anonymous
    """
    assert comment_id < self.comment_count, "Comment does not exist"
    
    author: address = empty(address)
    # Return author only if comment is revealed
    if self.comments[comment_id].is_revealed:
        author = self.comments[comment_id].author
    
    return (
        self.comments[comment_id].content,
        self.comments[comment_id].timestamp,
        author,
        self.comments[comment_id].is_truly_anonymous
    )

@external
def update_fees(new_comment_fee: uint256, new_reveal_fee: uint256, new_true_anonymity_fee: uint256):
    """
    @notice Update the fees for the contract
    @param new_comment_fee New fee to post a comment
    @param new_reveal_fee New fee to reveal an identity
    @param new_true_anonymity_fee New fee for true anonymity
    """
    assert msg.sender == self.owner, "Only owner can update fees"
    self.comment_fee = new_comment_fee
    self.reveal_fee = new_reveal_fee
    self.true_anonymity_fee = new_true_anonymity_fee

@external
def update_fee_recipient(new_recipient: address):
    """
    @notice Update the fee recipient address
    @param new_recipient New address to receive fees
    """
    assert msg.sender == self.owner, "Only owner can update fee recipient"
    self.fee_recipient = new_recipient
=======
# @version ^0.3.0

# A zero address constant (used when the identity should not be revealed)
ZERO_ADDRESS: constant(address) = 0x0000000000000000000000000000000000000000

# Define a Comment struct.
# - text: the comment content (max 256 characters in this example)
# - author: the address of the user who posted the comment
# - protected: true if the sender paid the extra fee for actual anonymity
# - revealed: true if someone paid to reveal this comment’s identity
struct Comment:
    text: String[256]
    author: address
    protected: bool
    revealed: bool

owner: public(address)
posting_fee: public(uint256)
reveal_fee: public(uint256)
anonymity_fee: public(uint256)
comment_count: public(uint256)

# Mapping to store comments by their ID.
comments: public(HashMap[uint256, Comment])
# Mapping to store whitelisted addresses.
whitelist: public(HashMap[address, bool])

# Events for logging actions
event CommentPosted:
    comment_id: uint256
    poster: address

event CommentRevealed:
    comment_id: uint256
    revealer: address

@external
def __init__(_posting_fee: uint256, _reveal_fee: uint256, _anonymity_fee: uint256):
    """
    @notice Contract constructor sets the owner and fee parameters.
    @param _posting_fee The fee required to post a comment.
    @param _reveal_fee The fee required to reveal a comment’s identity.
    @param _anonymity_fee The additional fee to protect one’s identity.
    """
    self.owner = msg.sender
    self.posting_fee = _posting_fee
    self.reveal_fee = _reveal_fee
    self.anonymity_fee = _anonymity_fee
    self.comment_count = 0

@external
def add_to_whitelist(user: address):
    """
    @notice Add an address to the whitelist (only callable by owner).
    @param user The address to whitelist.
    """
    assert msg.sender == self.owner, "Only owner can add whitelist"
    self.whitelist[user] = True

@external
def remove_from_whitelist(user: address):
    """
    @notice Remove an address from the whitelist (only callable by owner).
    @param user The address to remove.
    """
    assert msg.sender == self.owner, "Only owner can remove from whitelist"
    self.whitelist[user] = False

@external
@payable
def post_comment(text: String[256], opt_anonymity: bool):
    """
    @notice Post a comment if the sender is whitelisted.
            The sender must pay the base posting fee and, if opting for true anonymity, the extra anonymity fee.
    @param text The content of the comment.
    @param opt_anonymity Set to True to pay for protection so that later reveals won’t show your address.
    """
    # Only allow whitelisted users
    assert self.whitelist[msg.sender], "Not whitelisted"
    
    # Calculate required fee
    required_fee: uint256 = self.posting_fee
    if opt_anonymity:
        required_fee += self.anonymity_fee
    assert msg.value >= required_fee, "Insufficient fee sent"
    
    # Store the comment with the sender’s address and anonymity flag.
    comment_id: uint256 = self.comment_count
    self.comments[comment_id] = Comment({
        text: text,
        author: msg.sender,
        protected: opt_anonymity,
        revealed: False
    })
    self.comment_count += 1
    
    log CommentPosted(comment_id, msg.sender)
    
    # Forward received fee to the owner’s wallet.
    send(self.owner, msg.value)

@external
@payable
def reveal_comment(comment_id: uint256):
    """
    @notice Reveal the identity behind a comment.
            Anyone can pay the reveal fee to mark a comment as revealed.
    @param comment_id The ID of the comment to reveal.
    """
    # Ensure the comment exists
    assert comment_id < self.comment_count, "Invalid comment ID"
    comment: Comment = self.comments[comment_id]
    # Prevent re-revealing an already revealed comment
    assert not comment.revealed, "Comment already revealed"
    # Check that the reveal fee is met
    assert msg.value >= self.reveal_fee, "Insufficient reveal fee"
    
    # Mark the comment as revealed
    self.comments[comment_id].revealed = True
    log CommentRevealed(comment_id, msg.sender)
    
    # Forward reveal fee to the owner’s wallet.
    send(self.owner, msg.value)

@view
@external
def get_comment(comment_id: uint256) -> (String[256], bool, address):
    """
    @notice Get a comment’s details.
    @param comment_id The ID of the comment.
    @return A tuple: (comment text, revealed flag, author address).
            If the comment is not revealed or is protected, the returned address is ZERO_ADDRESS.
    """
    assert comment_id < self.comment_count, "Invalid comment ID"
    comment: Comment = self.comments[comment_id]
    if not comment.revealed:
        # Identity is hidden if not revealed.
        return (comment.text, False, ZERO_ADDRESS)
    else:
        if comment.protected:
            # Even if revealed, a protected comment will not show the real address.
            return (comment.text, True, ZERO_ADDRESS)
        else:
            return (comment.text, True, comment.author)
>>>>>>> Stashed changes
