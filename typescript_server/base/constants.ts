import { secretKey } from "../configuration.json";

export class Constants {
  public static SecretKey: String = process.env.SECRET_KEY || secretKey;
}
