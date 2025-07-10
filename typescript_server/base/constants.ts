import { env } from "process";
import { secretKey } from "../configuration.json";

export class Constants {
  public static SecretKey: String = env.SECRET_KEY || secretKey;
}
