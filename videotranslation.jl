using Knet
using JLD
using Images
using Colors

function main()
	fpath = "E:/Datasets/Flickr30k/flickr30k-images/"
	cpath = "E:/Datasets/COCO2014/train2014/"
	key = ".jpg"
	imageSize = 224

	nepochs = 1
	batchsize = 10

	image_names = filter(x->contains(x,key), readdir(fpath))
	numbatches = 10#div(size(image_names,1), batchsize)

	# Load VGG-16 Model
	# vgg16 = JLD.load("vgg16.jld", "model")
	# Load the LSTM Model
	lstm = JLD.load("lstm.jld", "model")
	# Load caption vocabulary
	vocabulary = open("lstm_data/vocabulary.txt")
	dict = Dict{Any,Int32}()
	for (n, s) in enumerate(eachline(f))
		dict[chomp(s)] = n
	end
	close(f)

	yt_train = readdlm("lstm_data/yt_pooled_vgg_fc7_mean_train.txt", ',', '\n'; use_mmap = true)
	yt_test = readdlm("lstm_data/yt_pooled_vgg_fc7_mean_test.txt", ',', '\n'; use_mmap = true)
	yt_val = readdlm("lstm_data/yt_pooled_vgg_fc7_mean_val.txt", ',', '\n'; use_mmap = true)

	for epoch = 1:nepochs

		for batch = 0:numbatches-1
			#Initialize x matrix
			x = zeros( imageSize, imageSize, 3, batchsize )

			for i = 1:batchsize
				index = batch * batchsize + i
				print("$(index)\n")
				#Read image file
				imgPath = "$(fpath)$(image_names[index])"
				img = load(imgPath)
				#Resize image to 224x224
				img = Images.imresize(img, (imageSize, imageSize))

				#Convert img to float values for RGB
				r = map(Float32,red(img))
				g = map(Float32,green(img))
				b = map(Float32,blue(img))

				x[:,:,1,i] = r
				x[:,:,2,i] = g
				x[:,:,3,i] = b
			end

			output = forw(lstm,x)
			print(output)

		end

	end

end

function train(f, data, loss)
	for (x,y) in data
		#use the dropout layer
		forw(f, x, dropout = true)
		back(f, y, loss)
		update!(f)
	end
end

function test(f, data, loss)
	sumloss = numloss = 0
	for (x,ygold) in data
		ypred = forw(f, x)
		sumloss += loss(ypred, ygold)
		numloss += 1
	end
	sumloss / numloss
end

main()
