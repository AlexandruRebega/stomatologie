class Operation:
    def __init__(self, id, name, price, duration):
    	self.name = name
    	self.id = id
    	self.price = price
    	self.duration = duration

class DiscountOperation:
    def __init__(self, id, name, price, discountPrice, duration):
    	self.name = name
    	self.id = id
    	self.price = price
    	self.duration = duration
    	self.discountPrice = discountPrice