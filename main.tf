data "terraform_remote_state" "remote_outputs_1" {
  backend = "remote"

  config = {
    organization = var.Terraformcloud_org_name
    workspaces = {
      name = var.workspaceforDualVPC-Parent

    }
  }
}


data "terraform_remote_state" "remote_outputs_2" {
  backend = "remote"

  config = {
    organization = var.Terraformcloud_org_name
    workspaces = {
      name = var.workspaceforDualDGW-Parent
    }
  }
}

data "terraform_remote_state" "remote_outputs_3" {
  backend = "remote"

  config = {
    organization = var.Terraformcloud_org_name
    workspaces = {
      name = var.workspaceforDualTGW-Parent
    }
  }
}


# this is  to associate DGW with TGW in Region 1 

resource "aws_dx_gateway_association" "main" {
  dx_gateway_id                  = data.terraform_remote_state.remote_outputs_2.outputs.Dx_Gateway_ID_01
  associated_gateway_id          = data.terraform_remote_state.remote_outputs_3.outputs.TGW_ID_Parent   
  allowed_prefixes = var.prefixes_from_onprem                                        
}


# this is  to associate DGW with TGW in Region 2

resource "aws_dx_gateway_association" "secondary" {
  dx_gateway_id                  = data.terraform_remote_state.remote_outputs_2.outputs.Dx_Gateway_ID_02 
  associated_gateway_id          = data.terraform_remote_state.remote_outputs_3.outputs.TGW_ID_Parent_2                                                     
  allowed_prefixes = var.prefixes_from_onprem
  provider = aws.secondary
}

# this is to attach TGW01 to VPC01 

resource "aws_ec2_transit_gateway_vpc_attachment" "TGW_to_VPC_1" {
  subnet_ids         = [data.terraform_remote_state.remote_outputs_1.outputs.Subnet_ID_Parent_01]
  transit_gateway_id = data.terraform_remote_state.remote_outputs_3.outputs.TGW_ID_Parent 
  vpc_id             = data.terraform_remote_state.remote_outputs_1.outputs.VPC_ID_Parent_01 
  tags = { 
    Name = var.attachment_name1
 }
}

# this is to attach TGW02 to VPC02

resource "aws_ec2_transit_gateway_vpc_attachment" "TGW_to_VPC_2" {
  subnet_ids         = [data.terraform_remote_state.remote_outputs_1.outputs.Subnet_ID_Parent_02]
  transit_gateway_id = data.terraform_remote_state.remote_outputs_3.outputs.TGW_ID_Parent_2 
  vpc_id             = data.terraform_remote_state.remote_outputs_1.outputs.VPC_ID_Parent_02
  provider = aws.secondary
  tags = { 
    Name = var.attachment_name2
 }
}

# this is to initiate TGW peering request 

resource "aws_ec2_transit_gateway_peering_attachment" "example" {
  peer_account_id         = var.authentication_key
  peer_region             = var.secondary_aws_region
  peer_transit_gateway_id = data.terraform_remote_state.remote_outputs_3.outputs.TGW_ID_Parent_2 
  transit_gateway_id      = data.terraform_remote_state.remote_outputs_3.outputs.TGW_ID_Parent 

  tags = {
    Name = "TGW Peering Requestor"
  }
}

# this is to accept TGW peering request 

resource "aws_ec2_transit_gateway_peering_attachment_accepter" "example4" {
  transit_gateway_attachment_id = aws_ec2_transit_gateway_peering_attachment.example.id
  tags = {
    Name = "TGW Peering Attachment Accepter"
  }

provider = aws.secondary
  
}


# Route's: VPC01 → TGW01
resource "aws_route" "route_1" {
  for_each = toset(var.route_1_VPC01_to_TGW01)

  route_table_id         = data.terraform_remote_state.remote_outputs_1.outputs.Main_RT_ID_Parent_01
  destination_cidr_block = each.value
  transit_gateway_id     = data.terraform_remote_state.remote_outputs_3.outputs.TGW_ID_Parent
}

# Route's: VPC02 → TGW02
resource "aws_route" "route_2" {
  for_each = toset(var.route_2_VPC02_to_TGW02)

  route_table_id         = data.terraform_remote_state.remote_outputs_1.outputs.Main_RT_ID_Parent_02
  destination_cidr_block = each.value
  transit_gateway_id     = data.terraform_remote_state.remote_outputs_3.outputs.TGW_ID_Parent_2

  provider = aws.secondary
}
