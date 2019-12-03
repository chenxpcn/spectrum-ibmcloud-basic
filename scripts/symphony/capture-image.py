import sys
import traceback
import SoftLayer

def main(params):
    try:
        if len(params) < 4:
            print("insufficient parameters!")
        else:
            sl_user = str(params[0])
            sl_apikey = str(params[1])
            instance_id = int(params[2])
            image_name = str(params[3])

            client = SoftLayer.create_client_from_env(username=sl_user, api_key=sl_apikey)

            # check if image with image_name exist or not
            # if exist, remove it
            imageManager = SoftLayer.ImageManager(client)
            image_list = imageManager.list_private_images(name=image_name)
            for image in image_list:
                info = imageManager.get_image(image['id'])
                print("found image with " + image_name + ", delete it")
                print(info)
                info = imageManager.delete_image(image['id'])

            # create transaction to capture the image
            vsManager = SoftLayer.VSManager(client)
            image_info = vsManager.capture(instance_id, image_name)
            print(image_info)

    except Exception:
        print(traceback.format_exc())

if __name__ == '__main__':
    main(sys.argv[1:])