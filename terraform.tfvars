# you can use like this ( using list of string ) 
# subnet_prefix = ["10.0.1.0/24","10.0.2.0/24"]
# or you can use like this ( using list of object) 
subnet_prefix = [{cidr_block="10.0.1.0/24" , name="prod-subnet-1"},{cidr_block="10.0.2.0/24" , name="prod-subnet-2"}]
# and call them like this var.subnet_prefix[0].cidr_block and var.subnet_prefix[0].name 

output-print="printing values in process ....."