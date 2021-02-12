import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { deployments } from "hardhat";

const governance: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
	const COLO = await deployments.getOrNull("COLO");
	const { log } = deployments;
	const TOKEN_URI = "QmcY5tWBFHjBW21g4R6EaATD5yY8zVDbEmU2kXx8z15VcE";

	if (!COLO) {
		const ethers = hre.ethers;

		const namedAccounts = await hre.getNamedAccounts();
		const threeDays = 259200;
		const [owner] = await ethers.getSigners();
		const governorOwner = process.env.GOVERNOR;
		let nonce = await owner.getTransactionCount();
		const coloAddress = ethers.utils.getContractAddress({
			from: namedAccounts.deployer,
			nonce: nonce++,
		});

		const timelockAddress = ethers.utils.getContractAddress({
			from: namedAccounts.deployer,
			nonce: nonce++,
		});

		const governorAddress = ethers.utils.getContractAddress({
			from: namedAccounts.deployer,
			nonce: nonce++,
		});

		const membershipsAddress = ethers.utils.getContractAddress({
			from: namedAccounts.deployer,
			nonce: nonce++,
		});

		const PointOfSaleAddress = ethers.utils.getContractAddress({
			from: namedAccounts.deployer,
			nonce: nonce++,
		});

		const ProofOfActionAddress = ethers.utils.getContractAddress({
			from: namedAccounts.deployer,
			nonce: nonce++,
		});

		const coloDeployment = await deployments.deploy("COLO", {
			from: namedAccounts.deployer,
			args: [governorOwner, membershipsAddress, PointOfSaleAddress, ProofOfActionAddress],
		});

		log(`COLO deployed at ${coloDeployment.address} for ${coloDeployment.receipt?.gasUsed}`);

		const timelockDeployment = await deployments.deploy("Timelock", {
			from: namedAccounts.deployer,
			args: [governorAddress, threeDays],
		});

		log(
			`Timelock deployed at ${timelockDeployment.address} for ${timelockDeployment.receipt?.gasUsed}`
		);

		const governorDeployment = await deployments.deploy("GovernorAlpha", {
			from: namedAccounts.deployer,
			args: [timelockAddress, coloAddress, governorOwner],
		});

		log(
			`Governor Alpha deployed at ${governorDeployment.address} for ${governorDeployment.receipt?.gasUsed}`
		);

		const membershipsDeployment = await deployments.deploy("Memberships", {
			from: namedAccounts.deployer,
			args: [TOKEN_URI, governorOwner, coloAddress],
		});

		log(
			`Memberships deployed at ${membershipsDeployment.address} for ${membershipsDeployment.receipt?.gasUsed}`
		);

		const posReward = ethers.utils.parseEther("1");

		const posDeployment = await deployments.deploy("PointOfSale", {
			from: namedAccounts.deployer,
			args: [coloAddress, membershipsAddress, governorOwner, posReward],
		});

		log(`posDeployment deployed at ${posDeployment.address} for ${posDeployment.receipt?.gasUsed}`);

		const powDeployment = await deployments.deploy("ProofOfAction", {
			from: namedAccounts.deployer,
			args: [coloAddress, membershipsAddress, governorOwner],
		});

		log(`powDeployment deployed at ${powDeployment.address} for ${powDeployment.receipt?.gasUsed}`);

		if (
			governorDeployment.address === governorAddress &&
			coloAddress === coloDeployment.address &&
			timelockAddress === timelockDeployment.address
		) {
			log("Address Match!");
		}
	} else {
		log("ColorDAO already deployed");
	}
};
export default governance;
